# frozen_string_literal: true

require 'fusuma/plugin/buffers/buffer'
require 'fusuma/plugin/touchscreen/math'

module Fusuma
  module Plugin
    module Buffers
      class TouchBuffer < Buffer
        DEFAULT_SOURCE = "libinput_touch_parser"
        DEFAULT_SECONDS_TO_KEEP = 100

        attr_reader :finger_events_map

        def initialize(*args)
          super()
          @finger_events_map = {}
          @mem = {}
          @last_event_time = nil
        end

        def config_param_types
          {
            source: [String],
            seconds_to_keep: [Float, Integer]
          }
        end

        def buffer(event)
          return if event&.tag != source

          @finger_events_map[event.record.finger] ||= []
          @finger_events_map[event.record.finger].push(event)
          reset_memoized

          self
        end

        def events
          raise NoMethodError, "Not supported, use finger_events_map instead"
        end

        def clear_expired(current_time: Time.now)
          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)

          clear if ended?
          @finger_events_map.each do |finger, events|
            next if events.empty?

            @finger_events_map[finger].select! do |e|
              current_time - e.time < @seconds_to_keep
            end
          end
          @finger_events_map.delete_if { |_, events| events.empty? }

          reset_memoized
        end

        def clear
          super
          @finger_events_map = {}
          reset_memoized
        end

        def empty?
          @finger_events_map.empty?
        end

        def finger
          @mem[:finger] ||= @finger_events_map.keys.count
        end

        def began?
          @mem[:began] ||= @finger_events_map.any? && @finger_events_map.all? { |_, events| events.first&.record.status == "begin" }
        end

        def ended?
          @mem[:ended] ||= @finger_events_map.any? && @finger_events_map.all? { |_, events| events.last&.record.status == "end" }
        end

        def moved?
          # TODO: a quicker way to do this?
          @mem[:moved] ||= @finger_events_map.any? && @finger_events_map.keys.all? { |finger| finger_movements.key?(finger) }
        end

        def duration
          @mem[:duration] ||= if ended?
                                end_time - begin_time
                              else
                                Time.now - begin_time
                              end
        end

        def begin_time
          @mem[:begin_time] ||= @finger_events_map.values.map { |events| events.first.time }.min
        end

        def end_time
          @mem[:end_time] ||= @finger_events_map.values.map { |events| events.last.time }.max
        end

        # { finger => { distance: Float, angle: Float } }
        def finger_movements
          @mem[:finger_movements] ||= @finger_events_map.map do |finger, events|
            position_events = events.select { |e| e.record.position? }
            next if position_events.size < 2 # we need at least first and last position

            first_position = position_events.first
            last_position = position_events.last

            case
            when (first_position.record.x_mm - last_position.record.x_mm).abs < axis_threshold
              orientation = :vertical
              direction = (last_position.record.y_mm - first_position.record.y_mm) <=> 0
              x_axis = (first_position.record.x_mm + last_position.record.x_mm) / 2.0
            when (first_position.record.y_mm - last_position.record.y_mm).abs < axis_threshold
              orientation = :horizontal
              direction = (last_position.record.x_mm - first_position.record.x_mm) <=> 0
              y_axis = (first_position.record.y_mm + last_position.record.y_mm) / 2.0
            else
              orientation = :diagonal
              k = (first_position.record.y_mm - last_position.record.y_mm) / (first_position.record.x_mm - last_position.record.x_mm)
              b = first_position.record.y_mm - k * first_position.record.x_mm
              direction_x = (last_position.record.x_mm - first_position.record.x_mm) <=> 0
              direction_y = (last_position.record.y_mm - first_position.record.y_mm) <=> 0
            end

            prev_position = first_position
            catch(:interrupted_movement) do
              position_events.each do |position|
                delta_x = position.record.x_mm - prev_position.record.x_mm
                delta_y = position.record.y_mm - prev_position.record.y_mm

                jitter_x = delta_x.abs < jitter_threshold
                jitter_y = delta_y.abs < jitter_threshold
                next if jitter_x && jitter_y

                case orientation
                when :vertical
                  throw(:interrupted_movement) unless jitter_y || (delta_y <=> 0) == direction
                  throw(:interrupted_movement) unless (position.record.x_mm - x_axis).abs < jitter_threshold
                when :horizontal
                  throw(:interrupted_movement) unless jitter_x || (delta_x <=> 0) == direction
                  throw(:interrupted_movement) unless (position.record.y_mm - y_axis).abs < jitter_threshold
                else
                  throw(:interrupted_movement) unless jitter_x || (delta_x <=> 0) == direction_x
                  throw(:interrupted_movement) unless jitter_y || (delta_y <=> 0) == direction_y
                  throw(:interrupted_movement) unless Touchscreen::Math.distance_from_line(position.record.x_mm, position.record.y_mm, k, b) < jitter_threshold
                end
                prev_position = position
              end

              case orientation
              when :vertical
                angle = direction == 1 ? 90 : 270
                distance = (last_position.record.y_mm - first_position.record.y_mm).abs
              when :horizontal
                angle = direction == 1 ? 0 : 180
                distance = (last_position.record.x_mm - first_position.record.x_mm).abs
              else
                angle = (Math.atan(k) * 180 / Math::PI).round
                case [direction_x, direction_y]
                when [1, 1]
                  angle += 0
                when [1, -1]
                  angle += 360
                when [-1, 1]
                  angle += 180
                when [-1, -1]
                  angle += 180
                end
                distance = Math.sqrt((last_position.record.x_mm - first_position.record.x_mm)**2 + (last_position.record.y_mm - first_position.record.y_mm)**2)
              end
              next if distance < jitter_threshold

              [
                finger,
                {
                  angle: angle,
                  distance: distance,
                  first_position: { x: first_position.record.x_mm, y: first_position.record.y_mm },
                  last_position: { x: last_position.record.x_mm, y: last_position.record.y_mm }
                }
              ]
            end
          end.compact.to_h
        end

        private

        def axis_threshold
          2.0 # TODO: make it configurable
        end

        def jitter_threshold
          5.0 # TODO: configurable
        end

        def reset_memoized
          @mem = {} if @mem.any?
        end

      end # class TouchBuffer
    end
  end
end
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
          @mem[:duration] ||= if @finger_events_map.empty?
                                0
                              elsif ended?
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

        def finger_movements
          @mem[:finger_movements] ||= @finger_events_map.map do |finger, events|
            position_events = events.select { |e| e.record.position? }
            next if position_events.size < 2 # we need at least first and last position

            first_position = { x: position_events.first.record.x_mm, y: position_events.first.record.y_mm }
            last_position = { x: position_events.last.record.x_mm, y: position_events.last.record.y_mm }
            distance = Touchscreen::Math.distance(first_position, last_position)
            next if distance < movement_threshold

            # TODO: check if there were trajectory changes in between?

            [finger, { first_position: first_position, last_position: last_position }]
          end.compact.to_h
        end

        private

        def movement_threshold
          0.5 # TODO: configurable
        end

        def reset_memoized
          @mem = {} if @mem.any?
        end

      end # class TouchBuffer
    end
  end
end
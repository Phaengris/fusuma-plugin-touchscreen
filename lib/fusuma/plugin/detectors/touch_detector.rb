# frozen_string_literal: true

require_relative './touch_detectors/tap_detector'
require_relative './touch_detectors/hold_detector'
require_relative './touch_detectors/swipe_detector'
require_relative './touch_detectors/pinch_detector'
require_relative './touch_detectors/rotate_detector'
require_relative './touch_detectors/edge_detector'

module Fusuma
  module Plugin
    module Detectors
      class TouchDetector < Detector
        class CancelledGestureError < StandardError; end

        SOURCES = %w[touch].freeze
        BEGIN_THRESHOLD = 0.5 # TODO: make configurable

        def initialize(*)
          super
          @detectors = [
            Fusuma::Plugin::Detectors::TouchDetectors::TapDetector,
            # Fusuma::Plugin::Detectors::TouchDetectors::HoldDetector,
            # Fusuma::Plugin::Detectors::TouchDetectors::SwipeDetector,
            # Fusuma::Plugin::Detectors::TouchDetectors::PinchDetector,
            # Fusuma::Plugin::Detectors::TouchDetectors::RotateDetector
          ]
        end

        def detect(buffers)
          MultiLogger.debug("> touch detector")

          touch_buffer = buffers.find { |b| b.type == 'touch' }
          return if touch_buffer.nil?

          @last_event_time = nil
          @looking_for = :begin
          @finger_events_map = {}
          # TODO: find if a gesture already saved into the buffer, if yes - start from there

          MultiLogger.debug("  processing #{touch_buffer.events.size} event(s)")

          buffer_enum = touch_buffer.events.each_with_index
          begin
            while (event, index = buffer_enum.next)
              MultiLogger.debug("  record: #{event.record.inspect}")
              case @looking_for
              when :begin
                look_for_begin_events(event: event)
              when :update
                look_for_update_or_end_events(event: event)
              else # not "begin" nor "update"?
                # TODO: handle it gracefully
                raise "Can't look for: #{@looking_for}"
              end

              if (gesture = detect_gesture)
                # MultiLogger.debug("  gesture detected: #{gesture.inspect}")
                # MultiLogger.debug("  finger events map: #{@finger_events_map.inspect}")

                # TODO: implement a buffer method for replacing events with a gesture
                touch_buffer.events.slice!(0..index)
                touch_buffer.events.unshift(gesture) unless gesture.finalized?

                buffer_enum.rewind
                return create_event(record: gesture.create_index_record)
              end
            end

          rescue StopIteration
            # TODO: save already built map so we can continue on the next iteration

          rescue CancelledGestureError => e
            # TODO: implement a buffer method for dropping events partially
            touch_buffer.events.slice!(0..index)
            return create_event(record: gesture.create_index_record(state: "cancelled")) if (gesture = detect_gesture)
          end

          nil
        end

        private

        def look_for_begin_events(event:)
          if @last_event_time && event.time - @last_event_time > BEGIN_THRESHOLD
            @looking_for = :update
            look_for_update_or_end_events(event: event)
            return
          end

          case event.record.status
          when 'begin'
            if @last_event_time.nil?
              @last_event_time = event.time
              @finger_events_map[event.record.finger] = [event]
            elsif event.time - @last_event_time < BEGIN_THRESHOLD
              # TODO: handle it gracefully
              raise "Unexpected begin event for finger #{event.record.finger}: #{event}" if @finger_events_map[event.record.finger]

              @last_event_time = event.time
              @finger_events_map[event.record.finger] = [event]
            else
              raise CancelledGestureError, "A new begin event outside of the time threshold: #{event}"
            end

          when 'update'
            if @finger_events_map[event.record.finger]
              if @finger_events_map[event.record.finger].last.record.status == 'end'
                # TODO: handle it gracefully
                raise "Unexpected finger update event after the end event: #{event}"
              end

              @finger_events_map[event.record.finger] << event
              if event.time - @last_event_time > BEGIN_THRESHOLD
                @looking_for = :update
              end
            end

          when 'end'
            if @finger_events_map[event.record.finger]
              if @finger_events_map[event.record.finger].last.record.status == 'end'
                # TODO: handle it gracefully
                raise "Unexpected end event for finger #{event.record.finger}: #{event}"
              end

              @finger_events_map[event.record.finger] << event
              @looking_for = :update
            end

          else
            # TODO: handle it gracefully
            raise "Unexpected event status: #{event.record.status}"
          end
        end

        def look_for_update_or_end_events(event:)
          case event.record.status
          when 'begin'
            raise CancelledGestureError, "A new begin event in the middle of the gesture: #{event}"

          when 'update'
            if @finger_events_map[event.record.finger]
              if @finger_events_map[event.record.finger].last.record.status == 'end'
                # TODO: handle it gracefully
                raise "Unexpected finger update event after the end event: #{event}"
              end

              @finger_events_map[event.record.finger] << event
            end

          when 'end'
            if @finger_events_map[event.record.finger]
              # TODO: check if end event is detected already
              @finger_events_map[event.record.finger] << event
            end

          else
            # TODO: handle it gracefully
            raise "Unexpected event status: #{event.record.status}"
          end
        end

        def detect_gesture
          @detectors.each do |detector|
            gesture = detector.new(@finger_events_map).detect
            return gesture if gesture
          end
          nil
        end

      end # class TouchDetector
    end
  end
end
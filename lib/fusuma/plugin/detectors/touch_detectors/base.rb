require 'memoized'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class Base
          include Memoized

          def initialize(finger_events_map)
            @finger_events_map = finger_events_map
          end

          def detect
            raise NotImplementedError
          end

          def create_index_record
            raise NotImplementedError
          end

          memoize def finger
            @finger_events_map.count
          end

          def finger_enum
            (0...finger).to_enum
          end

          memoize def finalized?
            @finger_events_map.all? do |_, finger_events|
              finger_events.last&.record.status == 'end'
            end
          end

          memoize def begin_time
            @finger_events_map.values.map do |finger_events|
              finger_events.first.time
            end.min
          end

          memoize def end_time
            @finger_events_map.values.map do |finger_events|
              finger_events.last.time
            end.max
          end

          memoize def begin_positions
            @finger_events_map.map do |finger, events|
              [finger, [events.first.record.x_mm, events.first.record.y_mm]]
            end.to_h
          end

          memoize def end_positions
            @finger_events_map.map do |finger, events|
              [finger, [update_events[finger].last.record.x_mm, update_events[finger].last.record.y_mm]]
            end.to_h
          end

          memoize def update_events
            @finger_events_map.map do |finger, events|
              # [finger, events[1..(events.last.record.status == 'end' ? -2 : -1)]]
              [finger, events.select { |event| event.record.status == 'update' }]
            end.to_h
          end

          memoize def movement?(finger)
            finger_enum.all? do |finger|
              update_events[finger].any? { |event| event.record.status == 'update' }
            end
          end

        end
      end
    end
  end
end
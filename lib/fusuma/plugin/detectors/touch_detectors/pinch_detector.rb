require_relative './base'
require 'fusuma/plugin/touchscreen/math'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class PinchDetector < Base

          def detect(touch_buffer)
            MultiLogger.debug('> pinch detector')

            MultiLogger.debug('  movement?')
            return unless touch_buffer.moved?

            MultiLogger.debug('  at least 2 fingers?')
            return unless touch_buffer.finger_movements.size >= 2

            MultiLogger.debug('  distance change between first 2 fingers?')
            first_finger, second_finger = touch_buffer.finger_movements.values_at(0, 1)
            begin_distance = Touchscreen::Math.distance(
              first_finger[:first_position][:x],
              first_finger[:first_position][:y],
              second_finger[:first_position][:x],
              second_finger[:first_position][:y]
            )
            end_distance = Touchscreen::Math.distance(
              first_finger[:last_position][:x],
              first_finger[:last_position][:y],
              second_finger[:last_position][:x],
              second_finger[:last_position][:y]
            )
            distance = end_distance - begin_distance
            return unless distance.abs > jitter_threshold

            direction = distance <=> 0
            MultiLogger.debug("  assuming direction is #{direction}, testing all pairs of fingers")
            is_pinch = catch(:not_a_pinch) do
              pairs = touch_buffer.finger_movements.keys.combination(2).to_a
              pairs.each do |finger1, finger2|
                begin_distance = Touchscreen::Math.distance(
                  touch_buffer.finger_movements[finger1][:first_position][:x],
                  touch_buffer.finger_movements[finger1][:first_position][:y],
                  touch_buffer.finger_movements[finger2][:first_position][:x],
                  touch_buffer.finger_movements[finger2][:first_position][:y]
                )
                end_distance = Touchscreen::Math.distance(
                  touch_buffer.finger_movements[finger1][:last_position][:x],
                  touch_buffer.finger_movements[finger1][:last_position][:y],
                  touch_buffer.finger_movements[finger2][:last_position][:x],
                  touch_buffer.finger_movements[finger2][:last_position][:y]
                )
                this_distance = end_distance - begin_distance
                if this_distance.abs < jitter_threshold
                  MultiLogger.debug("  !distance between fingers #{finger1} and #{finger2} is not changed enough (#{this_distance.abs}), not a pinch")
                  throw(:not_a_pinch)
                end
                this_direction = this_distance <=> 0
                if this_direction != direction
                  MultiLogger.debug("  !fingers #{finger1} and #{finger2} moved in direction #{this_direction}, not a pinch")
                  throw(:not_a_pinch)
                end
              end
              true
            end
            return unless is_pinch

            direction = direction == -1 ? :in : :out
            MultiLogger.debug("  pinch #{direction} detected!")

            Plugin::Events::Records::TouchRecords::PinchRecord.new(finger: touch_buffer.finger, direction: direction)
          end

          private

          def jitter_threshold
            5.0 # TODO: configurable
          end

        end # class PinchDetector
      end
    end
  end
end
require_relative './base'
require 'fusuma/plugin/touchscreen/math'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class RotateDetector < Base

          def detect(touch_buffer)
            MultiLogger.debug('> rotate detector')

            MultiLogger.debug('  movement?')
            return unless touch_buffer.moved?

            MultiLogger.debug('  at least 2 fingers?')
            return unless touch_buffer.finger_movements.size >= 2

            # MultiLogger.debug('  center is static?')
            # begin_center = Touchscreen::Math.center(touch_buffer.finger_movements.map { |_, v| v[:first_position] })
            # end_center = Touchscreen::Math.center(touch_buffer.finger_movements.map { |_, v| v[:last_position] })
            # return unless Touchscreen::Math.distance(begin_center, end_center) <= center_jitter_threshold

            MultiLogger.debug('  angle change for the first finger?')
            center = Touchscreen::Math.center(touch_buffer.finger_movements.map { |_, v| v[:first_position] })
            first_finger = touch_buffer.finger_movements[0]
            begin_angle = Touchscreen::Math.angle_between(center, first_finger[:first_position])
            end_angle = Touchscreen::Math.angle_between(center, first_finger[:last_position])
            angle_change = Touchscreen::Math.angles_difference(end_angle, begin_angle)
            MultiLogger.debug("    (#{angle_change})")
            return unless angle_change.abs > angle_threshold

            direction = angle_change <=> 0
            MultiLogger.debug("  assuming direction is #{direction} (from #{begin_angle} to #{end_angle}), testing all fingers")

            is_rotate = catch(:not_a_rotate) do
              touch_buffer.finger_movements.except(0).each do |finger, movement|
                begin_angle = Touchscreen::Math.angle_between(center, movement[:first_position])
                end_angle = Touchscreen::Math.angle_between(center, movement[:last_position])
                this_angle_change = Touchscreen::Math.angles_difference(end_angle, begin_angle)
                if this_angle_change.abs < angle_threshold
                  MultiLogger.debug("  !angle for finger #{finger} is not changed enough (#{this_angle_change.abs}), not a rotate")
                  throw(:not_a_rotate)
                end
                this_direction = this_angle_change <=> 0
                if this_direction != direction
                  MultiLogger.debug("  !finger #{finger} moved in direction #{this_direction} (from #{begin_angle} to #{end_angle}, not a rotate")
                  throw(:not_a_rotate)
                end
              end
              true
            end
            return unless is_rotate

            direction = direction == -1 ? :clockwise : :counterclockwise
            MultiLogger.debug("  rotate #{direction} detected!")

            Plugin::Events::Records::TouchRecords::RotateRecord.new(finger: touch_buffer.finger, direction: direction)
          end

          private

          def angle_threshold
            0.1 # TODO: make configurable
          end

        end # class RotateDetector
      end
    end
  end
end
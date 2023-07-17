require_relative './base'
require 'fusuma/plugin/touchscreen/math'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class SwipeDetector < Base

          def detect(touch_buffer)
            MultiLogger.debug('> swipe detector')

            MultiLogger.debug('  movement?')
            return unless touch_buffer.moved?

            MultiLogger.debug('  angles?')
            angles = touch_buffer.finger_movements.map do |_, movement|
              Touchscreen::Math.angle_between(movement[:first_position], movement[:last_position])
            end
            angles.combination(2).each do |angle1, angle2|
              if Touchscreen::Math.angles_difference(angle1, angle2).abs > movement_angle_threshold
                MultiLogger.debug("  !too much difference between #{angle1} and #{angle2}, not a swipe")
                return
              end
            end
            angle = Touchscreen::Math.angles_average(angles)

            MultiLogger.debug('  direction?')
            case angle
            when 0..(direction_angle_width / 2), (360 - (direction_angle_width / 2))..360
              direction = :right
            when (90 - (direction_angle_width / 2))..(90 + (direction_angle_width / 2))
              direction = :down
            when (180 - (direction_angle_width / 2))..(180 + (direction_angle_width / 2))
              direction = :left
            when (270 - (direction_angle_width / 2))..(270 + (direction_angle_width / 2))
              direction = :up
            else
              MultiLogger.debug("  !gesture angle of #{angle} does not fall into any direction")
              return
            end
            MultiLogger.debug("  swipe #{direction} detected!")

            Plugin::Events::Records::TouchRecords::SwipeRecord.new(finger: touch_buffer.finger, direction: direction)
          end

          private

          def movement_angle_threshold
            30 # TODO: configurable
          end

          def direction_angle_width
            45 # TODO: configurable
          end

        end # class SwipeDetector
      end
    end
  end
end
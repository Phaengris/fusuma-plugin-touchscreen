require_relative './tap_hold_base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class HoldDetector < TapHoldBase

          def detect(touch_buffer)
            MultiLogger.debug('> hold detector')

            MultiLogger.debug('  no movement?')
            if touch_buffer.moved?
              touch_buffer.finger_movements.each do |finger, movement|
                distance = Touchscreen::Math.distance(movement[:first_position], movement[:last_position])
                if distance > jitter_threshold
                  MultiLogger.debug("  finger #{finger} moved too much: #{distance} > #{jitter_threshold}")
                  return
                end
              end
            end

            MultiLogger.debug("  tap / hold threshold? (duration #{touch_buffer.duration})")
            return unless touch_buffer.duration > tap_hold_threshold

            MultiLogger.debug("  hold (#{touch_buffer.finger}) detected!")
            Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: touch_buffer.finger)
          end

        end # class HoldDetector
      end
    end
  end
end
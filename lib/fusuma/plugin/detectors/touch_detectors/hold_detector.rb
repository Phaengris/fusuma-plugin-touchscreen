require_relative './base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class HoldDetector < Base

          def detect(touch_buffer)
            MultiLogger.debug('> hold detector')

            MultiLogger.debug('  no movement?')
            return if touch_buffer.moved?

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
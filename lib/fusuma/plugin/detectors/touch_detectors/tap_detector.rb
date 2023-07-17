require_relative './tap_hold_base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class TapDetector < TapHoldBase

          def detect(touch_buffer)
            MultiLogger.debug('> tap detector')

            MultiLogger.debug('  no movement?')
            return if touch_buffer.moved?

            MultiLogger.debug('  began?')
            return unless touch_buffer.began?

            MultiLogger.debug('  ended?')
            return unless touch_buffer.ended?

            MultiLogger.debug("  tap / hold threshold? (duration #{touch_buffer.duration})")
            return unless touch_buffer.duration <= tap_hold_threshold

            MultiLogger.debug("  tap (#{touch_buffer.finger}) detected!")
            Plugin::Events::Records::TouchRecords::TapRecord.new(finger: touch_buffer.finger)
          end

        end # class TapDetector
      end
    end
  end
end
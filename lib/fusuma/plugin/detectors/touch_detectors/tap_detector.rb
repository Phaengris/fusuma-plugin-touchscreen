require_relative './base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class TapDetector < Base

          def detect(touch_buffer)
            MultiLogger.debug('> tap detector')

            MultiLogger.debug('  no movement?')
            return if touch_buffer.moved?

            MultiLogger.debug('  began?')
            return unless touch_buffer.began?

            MultiLogger.debug('  ended?')
            return unless touch_buffer.ended?

            MultiLogger.debug('  tap / hold threshold?')
            return unless touch_buffer.duration <= tap_hold_threshold

            MultiLogger.debug("  tap (#{touch_buffer.finger}) detected!")
            Plugin::Events::Records::TouchRecords::TapRecord.new(finger: touch_buffer.finger)
          end

          private

          def tap_hold_threshold
            0.5 # TODO: configurable
          end

        end # class TapDetector
      end
    end
  end
end
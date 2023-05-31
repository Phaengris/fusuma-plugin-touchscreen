require_relative './base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class TapDetector < Base
          TAP_HOLD_THRESHOLD = 0.5 # TODO: configurable
          JITTER_THRESHOLD = 1.0 # TODO: configurable

          def detect
            MultiLogger.debug('> tap detector')
            MultiLogger.debug('  finalized?')
            return unless finalized?
            MultiLogger.debug('  tap threshold?')
            return unless end_time - begin_time <= TAP_HOLD_THRESHOLD

            MultiLogger.debug('  jitter?')
            update_events.each do |finger, events|
              return unless events.all? do |event|
                event.record.x_mm.between?(begin_positions[finger][0] - JITTER_THRESHOLD, begin_positions[finger][0] + JITTER_THRESHOLD) &&
                  event.record.y_mm.between?(begin_positions[finger][1] - JITTER_THRESHOLD, begin_positions[finger][1] + JITTER_THRESHOLD)
              end
            end

            MultiLogger.debug('  tap detected!')
            Plugin::Events::Records::TouchRecords::TapRecord.new(finger: finger)
          end

        end
      end
    end
  end
end
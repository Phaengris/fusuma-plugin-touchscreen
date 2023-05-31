require_relative './base'

module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class SwipeDetector < Base
          MOVEMENT_THRESHOLD = 5.0 # TODO: configurable

          def detect
            MultiLogger.debug('> swipe detector')

            MultiLogger.debug('  movement?')
            return unless finger_enum.all? { |finger| movement?(finger) }

            # y_begin = k * x_begin + b
            # y_end = k * x_end + b
            # k = (y_end - y_begin) / (x_end - x_begin)
            # b = y_begin - k * x_begin

            vectors = finger_enum.map do |finger|
              if (begin_positions[finger][0] - end_positions[finger][0]).abs < 0.1

              end
            end

            puts "begin_positions: #{begin_positions.inspect}"
            puts "end_positions: #{end_positions.inspect}"

            nil
          end

        end
      end
    end
  end
end
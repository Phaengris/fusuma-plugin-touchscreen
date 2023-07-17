module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class TapHoldBase

          protected

          def tap_hold_threshold
            0.5 # TODO: configurable
          end

          def jitter_threshold
            5.0 # TODO: configurable
          end

        end # class TapHoldBase
      end
    end
  end
end
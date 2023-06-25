module Fusuma
  module Plugin
    module Detectors
      module TouchDetectors
        class Base
          def detect
            raise NotImplementedError, "override #{self.class.name}##{__method__}"
          end

          protected

          def tap_hold_threshold
            0.5 # TODO: configurable
          end

        end
      end
    end
  end
end
module Fusuma
  module Utils
    module Angle

      def self.difference(angle1, angle2)
        da = (angle1 - angle2).abs
        da > 180 ? 360 - da : da
      end

    end # module Angle
  end
end

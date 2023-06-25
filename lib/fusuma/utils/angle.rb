module Fusuma
  module Utils
    module Angle

      def self.difference(angle1, angle2)
        da = (angle1 - angle2).abs
        da > 180 ? 360 - da : da
      end

      def self.average(angles)
        sum_x = 0.0
        sum_y = 0.0

        angles.each do |angle|
          radians = angle * Math::PI / 180.0
          sum_x += Math.cos(radians)
          sum_y += Math.sin(radians)
        end

        average_radians = Math.atan2(sum_y, sum_x)
        average_degrees = average_radians * 180.0 / Math::PI
        average_degrees += 360.0 if average_degrees < 0

        average_degrees
      end

    end # module Angle
  end
end

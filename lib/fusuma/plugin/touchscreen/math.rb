module Fusuma
  module Plugin
    module Touchscreen
      module Math

        def self.angles_difference(angle1, angle2)
          da = (angle1 - angle2).abs
          da > 180 ? 360 - da : da
        end

        def self.angles_average(angles)
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

        def self.distance(x1, y1, x2, y2)
          ::Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)
        end

        def self.distance_from_line(x, y, k, b)
          (k * x + b - y).abs / ::Math.sqrt(k**2 + 1)
        end

      end # module Math
    end
  end
end
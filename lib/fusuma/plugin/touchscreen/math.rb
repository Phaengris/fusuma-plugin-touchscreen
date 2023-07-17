module Fusuma
  module Plugin
    module Touchscreen
      module Math

        def self.angles_difference(angle1, angle2)
          normalized_angle1 = normalize_angle(angle1)
          normalized_angle2 = normalize_angle(angle2)

          raw_difference = normalized_angle2 - normalized_angle1

          if raw_difference < -180
            raw_difference += 360
          elsif raw_difference > 180
            raw_difference -= 360
          end

          raw_difference
        end

        def self.normalize_angle(angle)
          angle %= 360
          angle < 0 ? angle + 360 : angle
        end
        private_class_method :normalize_angle

        def self.angles_average(angles)
          sum_x = 0.0
          sum_y = 0.0

          angles.each do |angle|
            radians = angle * ::Math::PI / 180.0
            sum_x += ::Math.cos(radians)
            sum_y += ::Math.sin(radians)
          end

          average_radians = ::Math.atan2(sum_y, sum_x)
          average_degrees = average_radians * 180.0 / ::Math::PI
          average_degrees += 360.0 if average_degrees < 0

          average_degrees
        end

        def self.distance(point1, point2)
          ::Math.sqrt((point1[:x] - point2[:x])**2 + (point1[:y] - point2[:y])**2)
        end

        def self.distance_from_line(x, y, k, b)
          (k * x + b - y).abs / ::Math.sqrt(k**2 + 1)
        end

        def self.center(points)
          x = points.map { |p| p[:x] }.reduce(:+) / points.size
          y = points.map { |p| p[:y] }.reduce(:+) / points.size
          { x: x, y: y }
        end

        def self.angle_between(base_point, other_point)
          radians = ::Math.atan2(other_point[:y] - base_point[:y], other_point[:x] - base_point[:x])
          degrees = radians * 180.0 / ::Math::PI
          degrees += 360.0 if degrees < 0
          degrees
        end

      end # module Math
    end
  end
end
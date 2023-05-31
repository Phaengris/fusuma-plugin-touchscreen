# frozen_string_literal: true

module Fusuma
  module Plugin
    module Parsers
      class TouchParser < Parser
        DEFAULT_SOURCE = 'libinput_command_input'

=begin
3-finger touch:

 event4   TOUCH_DOWN              +0.000s       0 (0) 58.64/44.04 (148.16/73.74mm)
 event4   TOUCH_DOWN              +0.000s       1 (1) 49.33/47.67 (124.63/79.84mm)
 event4   TOUCH_DOWN              +0.000s       2 (2) 43.54/64.23 (110.00/107.56mm)
 event4   TOUCH_UP                +0.079s       2 (2)
 event4   TOUCH_UP                +0.099s       1 (1)
 event4   TOUCH_UP                +0.108s       0 (0)
=end

=begin
2-finger swipe:

 event4   TOUCH_DOWN              +0.000s       0 (0) 27.07/42.62 (68.39/71.37mm)
 event4   TOUCH_DOWN              +0.000s       1 (1) 26.45/53.27 (66.82/89.21mm)
 event4   TOUCH_MOTION            +0.051s       1 (1) 26.84/53.27 (67.82/89.21mm)
 event4   TOUCH_MOTION            +0.061s       0 (0) 27.40/42.91 (69.24/71.86mm)
 event4   TOUCH_MOTION            +0.061s       1 (1) 27.21/53.28 (68.74/89.23mm)
 event4   TOUCH_MOTION            +0.071s       0 (0) 28.03/43.27 (70.82/72.47mm)
 event4   TOUCH_MOTION            +0.071s       1 (1) 27.67/53.33 (69.92/89.30mm)
 event4   TOUCH_MOTION            +0.082s       0 (0) 28.59/43.49 (72.24/72.84mm)
 event4   TOUCH_MOTION            +0.082s       1 (1) 28.43/53.37 (71.84/89.37mm)
 event4   TOUCH_MOTION            +0.091s       0 (0) 29.32/43.66 (74.08/73.12mm)
 event4   TOUCH_MOTION            +0.091s       1 (1) 28.90/53.41 (73.03/89.44mm)
 event4   TOUCH_MOTION            +0.101s       0 (0) 30.17/43.99 (76.24/73.67mm)
 event4   TOUCH_MOTION            +0.101s       1 (1) 29.84/53.21 (75.39/89.12mm)
 event4   TOUCH_MOTION            +0.111s       0 (0) 30.51/44.08 (77.08/73.81mm)
 event4   TOUCH_MOTION            +0.111s       1 (1) 30.47/53.35 (76.97/89.35mm)
 event4   TOUCH_MOTION            +0.121s       0 (0) 31.84/44.59 (80.45/74.67mm)
 event4   TOUCH_MOTION            +0.121s       1 (1) 31.65/53.73 (79.97/89.98mm)
 event4   TOUCH_MOTION            +0.131s       0 (0) 32.56/44.76 (82.26/74.95mm)
 event4   TOUCH_MOTION            +0.131s       1 (1) 32.62/54.21 (82.42/90.79mm)
 event4   TOUCH_MOTION            +0.141s       0 (0) 33.51/44.94 (84.66/75.26mm)
 event4   TOUCH_MOTION            +0.141s       1 (1) 33.49/54.46 (84.61/91.21mm)
 event4   TOUCH_MOTION            +0.151s       0 (0) 34.88/45.38 (88.13/76.00mm)
 event4   TOUCH_MOTION            +0.151s       1 (1) 35.05/54.74 (88.55/91.67mm)
 event4   TOUCH_MOTION            +0.162s       0 (0) 36.14/45.72 (91.32/76.56mm)
 event4   TOUCH_MOTION            +0.162s       1 (1) 36.62/55.28 (92.53/92.58mm)
 event4   TOUCH_MOTION            +0.171s       0 (0) 37.53/46.12 (94.82/77.23mm)
 event4   TOUCH_MOTION            +0.171s       1 (1) 38.21/55.84 (96.55/93.51mm)
 event4   TOUCH_MOTION            +0.181s       0 (0) 39.94/47.08 (100.92/78.84mm)
 event4   TOUCH_MOTION            +0.181s       1 (1) 39.91/56.03 (100.84/93.84mm)
 event4   TOUCH_UP                +0.220s       0 (0)
 event4   TOUCH_UP                +0.220s       1 (1)
=end

        def parse_record(record)
          MultiLogger.debug("#{self.class.name}##{__method__}")
          MultiLogger.debug("  record = #{record.inspect}")

          case record.to_s
          when /TOUCH_DOWN\s+\+(\d+\.\d+)s\s+(\d+)\s+\(\d+\)\s+(\d+\.\d+)\/(\d+\.\d+)\s+\((\d+\.\d+)\/(\d+\.\d+)mm\)/
            status = 'begin'
            time_offset = $1
            finger = $2
            x_px = $3
            y_px = $4
            x_mm = $5
            y_mm = $6

          when /TOUCH_MOTION\s+\+(\d+\.\d+)s\s+(\d+)\s+\(\d+\)\s+(\d+\.\d+)\/(\d+\.\d+)\s+\((\d+\.\d+)\/(\d+\.\d+)mm\)/
            status = 'update'
            time_offset = $1
            finger = $2
            x_px = $3
            y_px = $4
            x_mm = $5
            y_mm = $6

          when /TOUCH_UP\s+\+(\d+\.\d+)s\s+(\d+)\s+\(\d+\)/
            status = 'end'
            time_offset = $1
            finger = $2

          else
            return
          end

          Events::Records::TouchRecord.new(status: status,
                                           finger: finger,
                                           time_offset: time_offset,
                                           x_px: x_px,
                                           y_px: y_px,
                                           x_mm: x_mm,
                                           y_mm: y_mm)
        end

        def tag
          'libinput_touch_parser'
        end
      end
    end
  end
end
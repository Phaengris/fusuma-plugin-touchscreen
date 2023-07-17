# frozen_string_literal: true

require 'fusuma/plugin/parsers/parser'

module Fusuma
  module Plugin
    module Parsers
      class TouchParser < Parser
        DEFAULT_SOURCE = 'libinput_command_input'

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
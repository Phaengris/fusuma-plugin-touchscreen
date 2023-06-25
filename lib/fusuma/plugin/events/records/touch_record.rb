# frozen_string_literal: true

require 'fusuma/plugin/events/records/record'

require_relative './touch_records/tap_record'
require_relative './touch_records/hold_record'
require_relative './touch_records/swipe_record'

module Fusuma
  module Plugin
    module Events
      module Records
        class TouchRecord < Record
          attr_reader :status,
                      :finger,
                      :x_px,
                      :y_px,
                      :x_mm,
                      :y_mm,
                      :time_offset

          def initialize(status:, finger:, time_offset:, x_px: nil, y_px: nil, x_mm: nil, y_mm: nil)
            super()
            @status = status.to_s
            @finger = finger.to_i
            @time_offset = time_offset.to_f
            @x_px = x_px.to_f if x_px
            @y_px = y_px.to_f if y_px
            @x_mm = x_mm.to_f if x_mm
            @y_mm = y_mm.to_f if y_mm
          end

          def position?
            @x_px || @y_px
          end
        end
      end
    end
  end
end

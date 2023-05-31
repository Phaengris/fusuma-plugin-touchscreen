# frozen_string_literal: true

require_relative './touch_records/incomplete_gesture_record'
require_relative './touch_records/tap_record'

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

          def initialize(status:, finger:, time_offset:, x_px:, y_px:, x_mm:, y_mm:)
            super()
            @status = status.to_s
            @finger = finger.to_i
            @time_offset = time_offset.to_f
            @x_px = x_px.to_f
            @y_px = y_px.to_f
            @x_mm = x_mm.to_f
            @y_mm = y_mm.to_f
          end
        end
      end
    end
  end
end

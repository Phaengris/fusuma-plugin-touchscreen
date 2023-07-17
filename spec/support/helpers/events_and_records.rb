require 'fusuma/plugin/events/event'
require 'fusuma/plugin/events/records/touch_record'
require 'fusuma/plugin/events/records/text_record'

module Helpers
  module EventsAndRecords

    def generate_event(tag:, time: Time.now, record:)
      Fusuma::Plugin::Events::Event.new(tag: tag, record: record, time: time)
    end

    def generate_touch_record(status: 'begin', time_offset: 0, finger: 0, x_px: nil, y_px: nil, x_mm: nil, y_mm: nil)
      if status != 'end'
        x_px ||= 10
        y_px ||= 10
        x_mm ||= 10
        y_mm ||= 10
      end
      Fusuma::Plugin::Events::Records::TouchRecord.new(
        status: status,
        time_offset: time_offset,
        finger: finger,
        x_px: x_px,
        y_px: y_px,
        x_mm: x_mm,
        y_mm: y_mm
      )
    end

    def generate_touch_event(record: generate_touch_record, time: Time.now)
      generate_event(tag: 'libinput_touch_parser', record: record, time: time)
    end

    def generate_timer_record
      Fusuma::Plugin::Events::Records::TextRecord.new("timer")
    end

    def generate_timer_event(time: Time.now)
      generate_event(tag: "timer_input", record: generate_timer_record, time: time)
    end

  end
end
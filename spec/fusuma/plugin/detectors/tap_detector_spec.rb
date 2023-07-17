require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/tap_detector'
require 'fusuma/plugin/events/records/touch_records/tap_record'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::TapDetector do
    include_context 'with touch buffer'
    subject { described_class.new }

    before do
      allow(touch_buffer).to receive(:movement_threshold).and_return(0.5)
      allow(subject).to receive(:tap_hold_threshold).and_return(0.5)
      allow(subject).to receive(:jitter_threshold).and_return(5.0)
    end

    it 'no events' do
      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'not began in this cycle' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'end', finger: 1)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'not ended in this cycle' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'moved too much' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 20, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'end', finger: 1)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'too long' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t + 0.6, record: generate_touch_record(status: 'end', finger: 1)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'not moved' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t + 0.1, record: generate_touch_record(status: 'end', finger: 1)))
      pp touch_buffer.finger_movements

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::TapRecord)
    end

    it 'moved under jitter threshold' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t + 0.1, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10.1, y_mm: 10.1)))
      touch_buffer.buffer(generate_touch_event(time: t + 0.2, record: generate_touch_record(status: 'end', finger: 1)))

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::TapRecord)
    end

    it 'works on real data' do
      parser = Plugin::Parsers::TouchParser.new
      buffer = Plugin::Buffers::TouchBuffer.new
      lines = File.readlines("spec/samples/3-fingers-tap.txt").map(&:strip).reject(&:empty?)
      lines.each do |line|
        record = parser.parse_record(line)
        next unless record

        event = Plugin::Events::Event.new(tag: 'libinput_touch_parser', record: record)
        buffer.buffer(event)
      end
      gesture = subject.detect(buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::TapRecord)
      expect(gesture.finger).to eq(3)
    end
  end
end
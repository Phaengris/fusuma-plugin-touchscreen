require 'spec_helper'
require 'timecop'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/hold_detector'
require 'fusuma/plugin/events/records/touch_records/hold_record'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::HoldDetector do
    subject { described_class.new }
    let(:touch_buffer) { Plugin::Buffers::TouchBuffer.new }
    let(:t) { Time.now }

    before do
      allow(touch_buffer).to receive(:movement_threshold).and_return(0.5)
      allow(subject).to receive(:tap_hold_threshold).and_return(0.5)
      allow(subject).to receive(:jitter_threshold).and_return(5.0)
    end

    it 'no events' do
      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'under tap_hold_threshold' do
      touch_buffer.buffer(generate_touch_event(time: t - 0.1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'not moved' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::HoldRecord)
    end

    it 'moved under jitter_threshold' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 15)))

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::HoldRecord)
    end

    it 'moved more than jitter_threshold' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 20)))

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'works on real data' do
      parser = Plugin::Parsers::TouchParser.new
      buffer = Plugin::Buffers::TouchBuffer.new
      lines = File.readlines("spec/samples/1-finger-hold.txt").map(&:strip).reject(&:empty?)
      t = Time.now - 30
      lines.each do |line|
        record = parser.parse_record(line)
        next unless record

        event = Plugin::Events::Event.new(tag: 'libinput_touch_parser', record: record, time: t += 1)
        buffer.buffer(event)
      end
      gesture = subject.detect(buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::HoldRecord)
      expect(gesture.finger).to eq(1)
    end

  end
end
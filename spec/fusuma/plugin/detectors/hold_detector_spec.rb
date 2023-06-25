require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/hold_detector'
require 'fusuma/plugin/events/records/touch_records/hold_record'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::HoldDetector do
    subject { described_class.new }

    let(:touch_buffer) { double('touch_buffer') }

    before do
      allow(touch_buffer).to receive(:tap_hold_threshold).and_return(0.5)
    end

    it 'detects hold' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:duration).and_return(0.6)
      allow(touch_buffer).to receive(:finger).and_return(1)

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::HoldRecord)
    end

    it 'does not detect hold if touch_buffer.moved?' do
      allow(touch_buffer).to receive(:moved?).and_return(true)

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'does not detect hold if gesture duration is under tap_hold_threshold' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:duration).and_return(0.4)

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
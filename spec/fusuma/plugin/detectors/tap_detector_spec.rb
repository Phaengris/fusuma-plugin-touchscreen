require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/tap_detector'
require 'fusuma/plugin/events/records/touch_records/tap_record'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::TapDetector do
    subject { described_class.new }

    let(:touch_buffer) { double('touch_buffer') }

    before do
      allow(touch_buffer).to receive(:tap_hold_threshold).and_return(0.5)
    end

    it 'detects tap' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:began?).and_return(true)
      allow(touch_buffer).to receive(:ended?).and_return(true)
      allow(touch_buffer).to receive(:duration).and_return(0.1)
      allow(touch_buffer).to receive(:finger).and_return(1)

      expect(subject.detect(touch_buffer)).to be_a(Plugin::Events::Records::TouchRecords::TapRecord)
    end

    it 'does not detect tap if touch_buffer.moved?' do
      allow(touch_buffer).to receive(:moved?).and_return(true)

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'does not detect tap if gesture not began in this cycle' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:began?).and_return(false)

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'does not detect tap if gesture not ended in this cycle' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:began?).and_return(true)
      allow(touch_buffer).to receive(:ended?).and_return(false)

      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'does not detect tap if gesture duration is over tap_hold_threshold' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      allow(touch_buffer).to receive(:began?).and_return(true)
      allow(touch_buffer).to receive(:ended?).and_return(true)
      allow(touch_buffer).to receive(:duration).and_return(1.0)

      expect(subject.detect(touch_buffer)).to be nil
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
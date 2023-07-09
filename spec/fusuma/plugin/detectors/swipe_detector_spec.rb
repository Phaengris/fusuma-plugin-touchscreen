require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/swipe_detector'
require 'fusuma/plugin/events/records/touch_records/swipe_record'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::SwipeDetector do
    subject { described_class.new }
    let(:touch_buffer) { Plugin::Buffers::TouchBuffer.new }
    let(:t) { Time.now }

    before do
      allow(touch_buffer).to receive(:movement_threshold).and_return(0.5)
      allow(subject).to receive(:movement_angle_threshold).and_return(30)
      allow(subject).to receive(:direction_angle_width).and_return(45)
    end

    it 'no events' do
      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'not moved' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, just one finger' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 20, y_mm: 10)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.finger).to eq(1)
    end

    it 'moved, more fingers, angle difference too big' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 10, y_mm: 20)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, more fingers, angle difference under movement_angle_threshold' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 20, y_mm: 8)))
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 12)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.finger).to eq(2)
    end

    it 'swipe left' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 10)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.direction).to eq('left')
    end

    it 'swipe right' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.direction).to eq('right')
    end

    it 'swipe up' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 0)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.direction).to eq('up')
    end

    it 'swipe down' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.direction).to eq('down')
    end

    it 'wrong direction, up left' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 20, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'wrong direction, up right' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'wrong direction, down left' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 20, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'wrong direction, down right' do
      touch_buffer.buffer(generate_touch_event(time: t - 1, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'works on real data' do
      parser = Plugin::Parsers::TouchParser.new
      buffer = Plugin::Buffers::TouchBuffer.new
      lines = File.readlines("spec/samples/2-fingers-swipe-right.txt").map(&:strip).reject(&:empty?)
      lines.each do |line|
        record = parser.parse_record(line)
        next unless record

        event = Plugin::Events::Event.new(tag: 'libinput_touch_parser', record: record)
        buffer.buffer(event)
      end
      gesture = subject.detect(buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.finger).to eq(2)
      expect(gesture.direction).to eq('right')
    end
  end
end
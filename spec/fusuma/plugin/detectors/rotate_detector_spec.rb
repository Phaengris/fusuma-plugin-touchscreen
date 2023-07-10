require 'spec_helper'
require 'fusuma/plugin/detectors/touch_detectors/rotate_detector'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::RotateDetector do
    include_context 'with touch buffer'
    subject { described_class.new }

    before do
      allow(subject).to receive(:angle_threshold).and_return(0.1)
    end

    it 'no events' do
      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'not moved' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, only one finger' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 20, y_mm: 20)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, 2 fingers, but not enough angle change' do
      # left finger, a little bit to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 10.1)))
      # right finger, a little bit to the up
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 9.99)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, 2 fingers, enough angle change, but not same direction' do
      # left finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 15)))
      # right finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 15)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'moved, 2 fingers, enough angle change, same direction' do
      # left finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 15)))
      # right finger, to the up
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 5)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a Plugin::Events::Records::TouchRecords::RotateRecord
      expect(gesture.finger).to eq 2
      expect(gesture.direction).to eq 'counterclockwise'
    end

    it '2 fingers, clockwise' do
      # left finger, to the up
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 5)))
      # right finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 15)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a Plugin::Events::Records::TouchRecords::RotateRecord
      expect(gesture.finger).to eq 2
      expect(gesture.direction).to eq 'clockwise'
    end

    it '3 fingers, one moved into wrong direction' do
      # left finger, to the up
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 5)))
      # right finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 15)))
      # top finger, to the left
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 3, x_mm: 10, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 3, x_mm: 5, y_mm: 0)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it '3 fingers, same direction' do
      # left finger, to the up
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 0, y_mm: 5)))
      # right finger, to the down
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 20, y_mm: 15)))
      # top finger, to the right
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 3, x_mm: 10, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 3, x_mm: 15, y_mm: 0)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a Plugin::Events::Records::TouchRecords::RotateRecord
      expect(gesture.finger).to eq 3
      expect(gesture.direction).to eq 'clockwise'
    end

    it_behaves_like 'real sample',
                    detector_class: Plugin::Detectors::TouchDetectors::RotateDetector,
                    sample_path: 'spec/samples/2-fingers-rotate-clockwise.txt',
                    expected_gesture_class: Plugin::Events::Records::TouchRecords::RotateRecord,
                    expected_gesture_attributes: { finger: 2, direction: 'clockwise' }
    it_behaves_like 'real sample',
                    detector_class: Plugin::Detectors::TouchDetectors::RotateDetector,
                    sample_path: 'spec/samples/2-fingers-rotate-counterclockwise.txt',
                    expected_gesture_class: Plugin::Events::Records::TouchRecords::RotateRecord,
                    expected_gesture_attributes: { finger: 2, direction: 'counterclockwise' }
  end
end
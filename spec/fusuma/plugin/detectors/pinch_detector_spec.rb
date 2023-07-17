require 'fusuma/plugin/detectors/touch_detectors/pinch_detector'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetectors::PinchDetector do
    include_context 'with touch buffer'
    subject { described_class.new }

    before do
      allow(subject).to receive(:jitter_threshold).and_return(5.0)
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

    it 'moved, not enough distance change between first 2 fingers' do
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 8, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 10, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 12, y_mm: 10)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'just two fingers' do
      # inside down left
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 0, y_mm: 0)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 10, y_mm: 10)))
      # inside up right
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 20, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 10, y_mm: 10)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::PinchRecord)
      expect(gesture.finger).to eq(2)
      expect(gesture.direction).to eq('in')
    end

    it 'three fingers, the third finger moved in wrong direction' do
      # outside up right
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 30, y_mm: 0)))
      # outside down left
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 10, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 0, y_mm: 30)))
      # inside up left
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 3, x_mm: 30, y_mm: 30)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 3, x_mm: 20, y_mm: 20)))

      expect(subject.detect(touch_buffer)).to be_nil
    end

    it 'three fingers' do
      # outside up right
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 1, x_mm: 20, y_mm: 10)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 1, x_mm: 30, y_mm: 0)))
      # outside down left
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 2, x_mm: 10, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 2, x_mm: 0, y_mm: 30)))
      # outside down right
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'begin', finger: 3, x_mm: 20, y_mm: 20)))
      touch_buffer.buffer(generate_touch_event(time: t, record: generate_touch_record(status: 'update', finger: 3, x_mm: 30, y_mm: 30)))

      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::PinchRecord)
      expect(gesture.direction).to eq('out')
      expect(gesture.finger).to eq(3)
    end

    it_behaves_like 'real sample',
                    detector_class: Plugin::Detectors::TouchDetectors::PinchDetector,
                    sample_path: 'spec/samples/3-fingers-pinch-in.txt',
                    expected_gesture_class: Plugin::Events::Records::TouchRecords::PinchRecord,
                    expected_gesture_attributes: { finger: 3, direction: 'in' }
    it_behaves_like 'real sample',
                    detector_class: Plugin::Detectors::TouchDetectors::PinchDetector,
                    sample_path: 'spec/samples/3-fingers-pinch-out.txt',
                    expected_gesture_class: Plugin::Events::Records::TouchRecords::PinchRecord,
                    expected_gesture_attributes: { finger: 3, direction: 'out' }

  end
end
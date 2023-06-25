require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/parsers/touch_parser'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detectors/swipe_detector'
require 'fusuma/plugin/events/records/touch_records/swipe_record'

module Fusuma
  RSpec.shared_examples 'detects swipe' do |direction:, angles: |
    it direction do
      finger_movements = angles.each_with_index.map do |angle, index|
        [index + 1, { angle: angle, distance: 10 }]
      end.to_h
      allow(touch_buffer).to receive(:finger_movements).and_return(finger_movements)
      gesture = subject.detect(touch_buffer)
      expect(gesture).to be_a(Plugin::Events::Records::TouchRecords::SwipeRecord)
      expect(gesture.direction).to eq(direction)
    end
  end

  RSpec.describe Plugin::Detectors::TouchDetectors::SwipeDetector do
    subject { described_class.new }
    let(:touch_buffer) { double('touch_buffer') }

    before do
      allow(touch_buffer).to receive(:movement_angle_threshold).and_return(30)
      allow(touch_buffer).to receive(:direction_angle_width).and_return(45)
    end

    context 'detects swipe' do
      before do
        allow(touch_buffer).to receive(:moved?).and_return(true)
        allow(touch_buffer).to receive(:finger).and_return(2)
      end

      it_behaves_like 'detects swipe', direction: 'up', angles: [260, 280]
      it_behaves_like 'detects swipe', direction: 'down', angles: [80, 100]
      it_behaves_like 'detects swipe', direction: 'left', angles: [170, 190]
      it_behaves_like 'detects swipe', direction: 'right', angles: [10, 350]
    end

    it 'does not detect swipe if touch_buffer.moved? is false' do
      allow(touch_buffer).to receive(:moved?).and_return(false)
      expect(subject.detect(touch_buffer)).to be nil
    end

    it 'too much angle difference' do
      finger_movements = { '1': { angle: 10, distance: 10 }, '2': { angle: 100, distance: 10 } }
      allow(touch_buffer).to receive(:moved?).and_return(true)
      allow(touch_buffer).to receive(:finger_movements).and_return(finger_movements)
      expect(subject.detect(touch_buffer)).to be nil
    end
  end
end
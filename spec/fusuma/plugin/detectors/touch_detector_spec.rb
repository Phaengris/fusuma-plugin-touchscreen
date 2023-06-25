require 'timecop'
require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detector'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetector do
    subject { described_class.new }

    DETECTORS = [
      Fusuma::Plugin::Detectors::TouchDetectors::TapDetector,
      Fusuma::Plugin::Detectors::TouchDetectors::HoldDetector,
      Fusuma::Plugin::Detectors::TouchDetectors::SwipeDetector,
      Fusuma::Plugin::Detectors::TouchDetectors::PinchDetector,
      Fusuma::Plugin::Detectors::TouchDetectors::RotateDetector,
      Fusuma::Plugin::Detectors::TouchDetectors::EdgeDetector
    ].freeze

    it 'does nothing if no matching buffer' do
      buffer = double('buffer', type: 'not-touch')
      expect(subject.detect([buffer])).to eq []
    end

    it 'ends gesture if too much time passed' do
      gesture = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 1)

      DETECTORS.each do |klass|
        allow_any_instance_of(klass).to receive(:detect).and_return(nil)
      end
      allow_any_instance_of(Plugin::Detectors::TouchDetectors::HoldDetector).to receive(:detect).and_return(gesture)
      allow(subject).to receive(:event_expire_time).and_return(1)

      t = Time.now
      Timecop.freeze(t - 2) do
        touch_buffer = Plugin::Buffers::TouchBuffer.new
        touch_buffer.buffer(generate_touch_event(record: generate_touch_record(status: 'update'), time: t - 2))
        subject.detect([touch_buffer])
      end

      events = Timecop.freeze(t) do
        timer_buffer = Plugin::Buffers::TimerBuffer.new
        timer_buffer.buffer(generate_timer_event(time: t))
        subject.detect([timer_buffer])
      end

      expect(events.size).to eq 1
      expect(events.first.record.index.keys.map(&:symbol)).to eq [:hold, 1, :end]
    end

    it 'ends gesture if gesture ended' do

    end

    it 'ends gesture if new gesture began' do

    end

    it 'timer tick does nothing if no touch events' do

    end

    it 'calls detectors if touch events' do

    end

    it 'calls detectors if timer tick' do

    end

    context 'gesture detected' do
      it 'clears touch buffer' do

      end

      context 'repeatable, update' do
        it 'repeatable, matches last known gesture' do
          # expect update
        end

        it 'non-repeatable' do
          # do not expect update
        end

        it 'repeatable, does not match last known gesture' do
          # do not expect update
        end

        it 'repeatable, no last known gesture' do
          # do not expect update
        end
      end

      context 'repeatable, begin' do
        it 'ends last known repeatable gesture if any' do

        end

        it 'creates event' do

        end

        it 'creates begin event' do

        end
      end

      context 'non-repeatable' do
        it 'ends last known repeatable gesture if any' do

        end

        it 'creates event' do

        end
      end

    end # context 'gesture detected'

    private

    def generate_touch_record(status: 'begin', time_offset: 1.5, finger: 1, x_px: 49.33, y_px: 47.67, x_mm: 124.63, y_mm: 79.84)
      Plugin::Events::Records::TouchRecord.new(
        status: status,
        time_offset: time_offset,
        finger: finger,
        x_px: x_px,
        y_px: y_px,
        x_mm: x_mm,
        y_mm: y_mm
      )
    end

    def generate_touch_event(tag: 'libinput_touch_parser', record: generate_touch_record, time: Time.now)
      Plugin::Events::Event.new(tag: tag, record: record, time: time)
    end

    def generate_timer_event(time: Time.now)
      Plugin::Events::Event.new(time: time, tag: "timer_input", record: Plugin::Events::Records::TextRecord.new("timer"))
    end
  end # describe Plugin::Detectors::TouchDetector
end
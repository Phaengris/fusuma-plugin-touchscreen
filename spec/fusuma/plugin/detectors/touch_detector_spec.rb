require 'timecop'
require 'spec_helper'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/detectors/touch_detector'

module Fusuma
  RSpec.describe Plugin::Detectors::TouchDetector do
    subject { described_class.new }
    let(:detectors) { subject.instance_variable_get(:@detectors) }
    let(:tap_detector) { detectors.find { |d| d.is_a?(Plugin::Detectors::TouchDetectors::TapDetector) } }
    let(:hold_detector) { subject.instance_variable_get(:@hold_detector) }
    let(:swipe_detector) { detectors.find { |d| d.is_a?(Plugin::Detectors::TouchDetectors::SwipeDetector) } }
    before do
      expect(:detectors).not_to be_empty
      expect(tap_detector).to be_a(Plugin::Detectors::TouchDetectors::TapDetector)
      expect(hold_detector).to be_a(Plugin::Detectors::TouchDetectors::HoldDetector)
      expect(swipe_detector).to be_a(Plugin::Detectors::TouchDetectors::SwipeDetector)

      detectors.each do |detector|
        allow(detector).to receive(:detect).and_return(nil)
      end
    end

    it 'does nothing if no matching buffer' do
      buffer = double('buffer', type: 'not-touch')
      expect(subject.detect([buffer])).to eq []
    end

    it 'ends gesture if too much time passed' do
      allow(hold_detector).to receive(:detect).and_call_original
      allow(hold_detector).to receive(:tap_hold_threshold).and_return(1)
      allow(subject).to receive(:event_expire_time).and_return(1)

      t = Time.now
      touch_buffer = Plugin::Buffers::TouchBuffer.new
      Timecop.freeze(t - 4) do
        touch_buffer.buffer(generate_touch_event(record: generate_touch_record(status: 'update'), time: t - 4))
      end
      # 2 seconds - enough to detect hold gesture
      # event is not expired because of there's no event yet
      events = Timecop.freeze(t - 2) do
        # here we detect hold gesture, which makes it the last gesture known to the detector
        subject.detect([touch_buffer])
      end
      expect(events.size).to eq 2
      expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 1]
      expect(events[1].record.index.keys.map(&:symbol)).to eq [:hold, 1, :begin]

      # now the last gesture becomes 1 second old
      events = Timecop.freeze(t) do
        timer_buffer = Plugin::Buffers::TimerBuffer.new
        timer_buffer.buffer(generate_timer_event(time: t))
        # here we waited for too long time without new events
        subject.detect([timer_buffer])
      end

      expect(events.size).to eq 1
      expect(events.first.record.index.keys.map(&:symbol)).to eq [:hold, 1, :end]
    end

    it 'ends gesture if end event is found' do
      allow(hold_detector).to receive(:detect).and_call_original
      allow(hold_detector).to receive(:tap_hold_threshold).and_return(1)
      # let's guarantee the event won't be expired
      allow(subject).to receive(:event_expire_time).and_return(10)

      t = Time.now
      touch_buffer = Plugin::Buffers::TouchBuffer.new
      Timecop.freeze(t - 4) do
        touch_buffer.buffer(generate_touch_event(record: generate_touch_record(status: 'update'), time: t - 4))
      end
      # 2 seconds - enough to detect hold gesture
      # event is not expired because of there's no event yet
      events = Timecop.freeze(t - 2) do
        # here we detect hold gesture, which makes it the last gesture known to the detector
        subject.detect([touch_buffer])
      end

      # now we send end event
      events = Timecop.freeze(t) do
        touch_buffer.buffer(generate_touch_event(record: generate_touch_record(status: 'end'), time: t))
        subject.detect([touch_buffer])
      end
      expect(events.size).to eq 1
      expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 1, :end]
    end

    it 'ends gesture if new gesture began' do
      record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
      allow(hold_detector).to receive(:detect).and_return(record)

      touch_buffer = Plugin::Buffers::TouchBuffer.new
      touch_buffer.buffer(generate_touch_event)
      # let's push the hold gesture as the last known gesture
      events = subject.detect([touch_buffer])
      expect(events.size).to eq 2
      expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0]
      expect(events[1].record.index.keys.map(&:symbol)).to eq [:hold, 0, :begin]

      record = Plugin::Events::Records::TouchRecords::SwipeRecord.new(finger: 0, direction: 'up')
      allow(hold_detector).to receive(:detect).and_return(nil)
      allow(swipe_detector).to receive(:detect).and_return(record)

      # now let's not issue any more events for the hold gesture, but start a new swipe gesture
      touch_buffer.buffer(generate_touch_event)
      events = subject.detect([touch_buffer])
      expect(events.size).to eq 3
      expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0, :end]
      expect(events[1].record.index.keys.map(&:symbol)).to eq [:swipe, 0, :up]
      expect(events[2].record.index.keys.map(&:symbol)).to eq [:swipe, 0, :up, :begin]
    end

    it 'timer tick does nothing if no touch events' do
      timer_buffer = Plugin::Buffers::TimerBuffer.new
      timer_buffer.buffer(generate_timer_event)
      detectors.each do |detector|
        expect(detector).not_to receive(:detect)
      end
      subject.detect([timer_buffer])
    end

    it 'calls detectors if touch events' do
      touch_buffer = Plugin::Buffers::TouchBuffer.new
      touch_buffer.buffer(generate_touch_event)
      detectors.each do |detector|
        expect(detector).to receive(:detect)
      end
      subject.detect([touch_buffer])
    end

    it 'calls detectors if timer tick' do
      touch_buffer = Plugin::Buffers::TouchBuffer.new
      touch_buffer.buffer(generate_touch_event)
      # we call detect which won't detect any gesture yet, but will save the reference to the touch buffer
      subject.detect([touch_buffer])
      timer_buffer = Plugin::Buffers::TimerBuffer.new
      timer_buffer.buffer(generate_timer_event)
      # in fact only the hold detector benefits from timer ticks for now
      expect(hold_detector).to receive(:detect)
      subject.detect([timer_buffer])
    end

    context 'gesture detected' do
      it 'clears touch buffer' do
        record = Plugin::Events::Records::TouchRecords::TapRecord.new(finger: 0)
        allow(tap_detector).to receive(:detect).and_return(record)
        touch_buffer = Plugin::Buffers::TouchBuffer.new
        touch_buffer.buffer(generate_touch_event)
        expect(touch_buffer).to receive(:clear)
        subject.detect([touch_buffer])
      end

      context 'repeatable' do
        it 'creates event' do
          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
          allow(hold_detector).to receive(:detect).and_return(record)
          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])
          expect(events.size).to eq 2
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0]
          expect(events[1].record.index.keys.map(&:symbol)).to eq [:hold, 0, :begin]
        end

        it 'matches last known gesture' do
          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
          allow(hold_detector).to receive(:detect).and_return(record)

          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          # make it the last known gesture
          subject.detect([touch_buffer])

          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])

          expect(events.size).to eq 1
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0, :update]
        end

        it 'does not match last known gesture' do
          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
          allow(hold_detector).to receive(:detect).and_return(record)

          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          # make it the last known gesture
          subject.detect([touch_buffer])

          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 1)
          allow(hold_detector).to receive(:detect).and_return(record)
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])

          expect(events.size).to eq 3
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0, :end]
          expect(events[1].record.index.keys.map(&:symbol)).to eq [:hold, 1]
          expect(events[2].record.index.keys.map(&:symbol)).to eq [:hold, 1, :begin]
        end

        it 'no last known gesture' do
          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
          allow(hold_detector).to receive(:detect).and_return(record)

          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])

          expect(events.size).to eq 2
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0]
          expect(events[1].record.index.keys.map(&:symbol)).to eq [:hold, 0, :begin]
        end
      end

      context 'non-repeatable' do
        it 'ends last known repeatable gesture if any' do
          record = Plugin::Events::Records::TouchRecords::HoldRecord.new(finger: 0)
          allow(hold_detector).to receive(:detect).and_return(record)

          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          # make it the last known gesture
          subject.detect([touch_buffer])

          allow(hold_detector).to receive(:detect).and_return(nil)
          record = Plugin::Events::Records::TouchRecords::TapRecord.new(finger: 0)
          allow(tap_detector).to receive(:detect).and_return(record)
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])

          expect(events.size).to eq 2
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:hold, 0, :end]
          expect(events[1].record.index.keys.map(&:symbol)).to eq [:tap, 0]
        end

        it 'creates event' do
          record = Plugin::Events::Records::TouchRecords::TapRecord.new(finger: 0)
          allow(tap_detector).to receive(:detect).and_return(record)
          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])
          expect(events.size).to eq 1
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:tap, 0]
        end

        it 'does not repeat' do
          record = Plugin::Events::Records::TouchRecords::TapRecord.new(finger: 0)
          allow(tap_detector).to receive(:detect).and_return(record)

          touch_buffer = Plugin::Buffers::TouchBuffer.new
          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])
          expect(events.size).to eq 1
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:tap, 0]

          touch_buffer.buffer(generate_touch_event)
          events = subject.detect([touch_buffer])
          expect(events.size).to eq 1
          expect(events[0].record.index.keys.map(&:symbol)).to eq [:tap, 0]
        end
      end
    end # context 'gesture detected'

  end # describe Plugin::Detectors::TouchDetector
end
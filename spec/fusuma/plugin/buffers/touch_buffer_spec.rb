require 'spec_helper'
require 'timecop'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/events/records/touch_record'

module Fusuma
  RSpec.describe Plugin::Buffers::TouchBuffer do
    subject { described_class.new }

    it 'builds finger_events_map' do
      event = generate_touch_event
      subject.buffer(event)
      expect(subject.finger_events_map[event.record.finger]).not_to be_empty
      expect(subject.finger_events_map[event.record.finger].first).to eq event
    end


    it 'clears finger_events_map' do
      event = generate_touch_event
      subject.buffer(event)
      subject.clear
      expect(subject.finger_events_map).to be_empty
    end

    describe '#clear_expired' do
      it 'outdated' do
        allow(subject).to receive(:config_params).and_call_original
        allow(subject).to receive(:config_params).with(:seconds_to_keep).and_return(50)
        expired_event = generate_touch_event(time: Time.now - 100)
        actual_event = generate_touch_event
        subject.buffer(expired_event)
        subject.buffer(actual_event)
        subject.clear_expired
        expect(subject.finger_events_map[actual_event.record.finger]).not_to include(expired_event)
        expect(subject.finger_events_map[actual_event.record.finger]).to include(actual_event)
      end

      it 'ended' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'begin')))
        subject.clear_expired
        expect(subject.finger_events_map).not_to be_empty

        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'end')))
        subject.clear_expired
        expect(subject.finger_events_map).to be_empty
      end
    end

    describe '#empty?' do
      it 'is empty' do
        expect(subject.empty?).to be_truthy
      end

      it 'is not empty' do
        event = generate_touch_event
        subject.buffer(event)
        expect(subject.empty?).to be_falsey
      end
    end

    describe '#finger' do
      it 'returns 0 if finger_events_map is empty' do
        expect(subject.finger).to eq 0
      end

      it 'returns count of fingers' do
        subject.buffer(generate_touch_event(record: generate_touch_record(finger: 1)))
        subject.buffer(generate_touch_event(record: generate_touch_record(finger: 2)))
        expect(subject.finger).to eq 2
      end

      it 'is based on count of fingers, not finger number' do
        subject.buffer(generate_touch_event(record: generate_touch_record(finger: 2)))
        expect(subject.finger).to eq 1
      end
    end

    describe '#began?' do
      it 'not began yet' do
        expect(subject.began?).to be_falsey
      end

      it 'began' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'begin')))
        expect(subject.began?).to be_truthy
      end

      it 'doesn\'t contain begin events (being updated or so, but began before that)' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'update')))
        expect(subject.began?).to be_falsey
      end

      it 'one finger began, other continued to update' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'begin', finger: 1)))
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'update', finger: 2)))
        expect(subject.began?).to be_falsey
      end
    end

    describe '#ended?' do
      it 'not ended yet' do
        expect(subject.ended?).to be_falsey
      end

      it 'ended' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'end')))
        expect(subject.ended?).to be_truthy
      end

      it 'doesn\'t contain end events (being updated or so, but ended before that)' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'update')))
        expect(subject.ended?).to be_falsey
      end

      it 'one finger ended, other continued to update' do
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'end', finger: 1)))
        subject.buffer(generate_touch_event(record: generate_touch_record(status: 'update', finger: 2)))
        expect(subject.ended?).to be_falsey
      end
    end

    describe '#finger_movements / #moved' do
      before do
        allow(subject).to receive(:movement_threshold).and_return(0.5)
      end

      it 'returns empty array if finger_events_map is empty' do
        expect(subject.finger_movements).to be_empty
        expect(subject.moved?).to be_falsey
      end

      it 'no movement if only one event' do
        event = generate_touch_event
        subject.buffer(event)
        expect(subject.finger_movements).to be_empty
        expect(subject.moved?).to be_falsey
      end

      it 'does not detect movement lesser than movement threshold' do
        event1 = generate_touch_event(record: generate_touch_record(status: 'begin', x_mm: 0, y_mm: 0))
        event2 = generate_touch_event(record: generate_touch_record(status: 'update', x_mm: 0.4, y_mm: 0))
        subject.buffer(event1)
        subject.buffer(event2)
        expect(subject.finger_movements).to be_empty
        expect(subject.moved?).to be_falsey
      end

      it 'detects movement outside jitter threshold' do
        event1 = generate_touch_event(record: generate_touch_record(status: 'begin', x_mm: 0, y_mm: 0))
        event2 = generate_touch_event(record: generate_touch_record(status: 'update', x_mm: 1, y_mm: 2))
        subject.buffer(event1)
        subject.buffer(event2)
        expect(subject.finger_movements).to eq({ 1 => { first_position: { x: 0, y: 0 }, last_position: { x: 1, y: 2 } } })
        expect(subject.moved?).to be_truthy
      end
    end

    describe '#begin_time' do
      it 'returns nil if no begin event' do
        expect(subject.begin_time).to be_nil
      end

      it 'returns begin event time' do
        begin_event = generate_touch_event(time: Time.now - 60, record: generate_touch_record(status: 'begin'))
        subject.buffer(begin_event)
        update_event = generate_touch_event(time: Time.now, record: generate_touch_record(status: 'end'))
        subject.buffer(update_event)
        expect(subject.begin_time).to eq(begin_event.time)
      end
    end

    describe '#end_time' do
      it 'returns nil if no end event' do
        expect(subject.end_time).to be_nil
      end

      it 'returns end event time' do
        begin_event = generate_touch_event(time: Time.now - 60, record: generate_touch_record(status: 'begin'))
        subject.buffer(begin_event)
        end_event = generate_touch_event(time: Time.now, record: generate_touch_record(status: 'end'))
        subject.buffer(end_event)
        expect(subject.end_time).to eq(end_event.time)
      end
    end

    describe '#duration' do
      it 'returns nil if no begin event' do
        expect(subject.duration).to be_nil
      end

      it 'gesture ended' do
        t = Time.now
        begin_event = generate_touch_event(time: t - 60, record: generate_touch_record(status: 'begin'))
        subject.buffer(begin_event)
        update_event = generate_touch_event(time: t - 40, record: generate_touch_record(status: 'update'))
        subject.buffer(update_event)
        end_event = generate_touch_event(time: t - 20, record: generate_touch_record(status: 'end'))
        subject.buffer(end_event)
        expect(subject.duration).to eq(40)
      end

      it 'gesture not ended' do
        t = Time.now
        Timecop.freeze(t) do
          begin_event = generate_touch_event(time: t - 60, record: generate_touch_record(status: 'begin'))
          subject.buffer(begin_event)
          update_event = generate_touch_event(time: t - 40, record: generate_touch_record(status: 'update'))
          subject.buffer(update_event)
          expect(subject.duration.round).to eq(60)
        end
      end
    end

  end
end
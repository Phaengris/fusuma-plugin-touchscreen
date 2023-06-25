require 'spec_helper'
require 'timecop'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/buffers/touch_buffer'
require 'fusuma/plugin/events/records/touch_record'

module Fusuma
  RSpec.shared_examples 'detecting movement' do |movement_name:, x1:, y1:, x2:, y2:, expected_angle:, expected_distance:|
    it movement_name do
      event1 = generate_touch_event(record: generate_touch_record(status: 'begin', x_mm: x1, y_mm: y1))
      event2 = generate_touch_event(record: generate_touch_record(status: 'update', x_mm: x2, y_mm: y2))
      subject.buffer(event1)
      subject.buffer(event2)
      expect(subject.finger_movements[1][:distance].round(2)).to eq expected_distance.round(2)
      expect(subject.finger_movements[1][:angle]).to eq expected_angle
    end
  end

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

    describe '#finger_movements' do
      before do
        allow(subject).to receive(:jitter_threshold).and_return(5)
      end

      it 'returns empty array if finger_events_map is empty' do
        expect(subject.finger_movements).to be_empty
      end

      it 'no movement if only one event' do
        event = generate_touch_event
        subject.buffer(event)
        expect(subject.finger_movements).to be_empty
      end

      it_behaves_like 'detecting movement',
                      movement_name: 'horizontal to the right',
                      x1: 0, y1: 0, x2: 10, y2: 0,
                      expected_angle: 0, expected_distance: 10
      it_behaves_like 'detecting movement',
                      movement_name: 'horizontal to the left',
                      x1: 10, y1: 0, x2: 0, y2: 0,
                      expected_angle: 180, expected_distance: 10
      it_behaves_like 'detecting movement',
                      movement_name: 'vertical to the top',
                      x1: 0, y1: 0, x2: 0, y2: 10,
                      expected_angle: 90, expected_distance: 10
      it_behaves_like 'detecting movement',
                      movement_name: 'vertical to the bottom',
                      x1: 0, y1: 10, x2: 0, y2: 0,
                      expected_angle: 270, expected_distance: 10
      it_behaves_like 'detecting movement',
                      movement_name: 'diagonal to the top right',
                      x1: 0, y1: 0, x2: 10, y2: 10,
                      expected_angle: 45, expected_distance: 14.14
      it_behaves_like 'detecting movement',
                      movement_name: 'diagonal to the top left',
                      x1: 10, y1: 0, x2: 0, y2: 10,
                      expected_angle: 135, expected_distance: 14.14
      it_behaves_like 'detecting movement',
                      movement_name: 'diagonal to the bottom left',
                      x1: 10, y1: 10, x2: 0, y2: 0,
                      expected_angle: 225, expected_distance: 14.14
      it_behaves_like 'detecting movement',
                      movement_name: 'diagonal to the bottom right',
                      x1: 0, y1: 10, x2: 10, y2: 0,
                      expected_angle: 315, expected_distance: 14.14

      it 'does not detect movement inside jitter threshold' do
        event1 = generate_touch_event(record: generate_touch_record(status: 'begin', x_mm: 0, y_mm: 0))
        event2 = generate_touch_event(record: generate_touch_record(status: 'update', x_mm: 4, y_mm: 0))
        subject.buffer(event1)
        subject.buffer(event2)
        expect(subject.finger_movements).to be_empty
      end
    end

    describe '#moved?' do
      it 'not moved yet' do
        allow(subject).to receive(:finger_movements).and_return({})
        expect(subject.moved?).to be_falsey
      end

      it 'moved' do
        allow(subject).to receive(:finger_movements).and_return({ 1 => { angle: 0, distance: 10 } })
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
  end
end
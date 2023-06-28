# frozen_string_literal: true

require 'fusuma/plugin/detectors/detector'

require_relative './touch_detectors/tap_detector'
require_relative './touch_detectors/hold_detector'
require_relative './touch_detectors/swipe_detector'
require_relative './touch_detectors/pinch_detector'
require_relative './touch_detectors/rotate_detector'
require_relative './touch_detectors/edge_detector'

module Fusuma
  module Plugin
    module Detectors
      class TouchDetector < Detector
        SOURCES = %w[touch timer].freeze

        def initialize(*)
          super
          @detectors = [
            # Fusuma::Plugin::Detectors::TouchDetectors::TapDetector,
            # Fusuma::Plugin::Detectors::TouchDetectors::SwipeDetector,
            Fusuma::Plugin::Detectors::TouchDetectors::PinchDetector,
          # Fusuma::Plugin::Detectors::TouchDetectors::RotateDetector,
          # Fusuma::Plugin::Detectors::TouchDetectors::EdgeDetector
          ].map(&:new)
          # @detectors << (@hold_detector = Fusuma::Plugin::Detectors::TouchDetectors::HoldDetector.new)
          @last_known_gesture = nil
        end

        def detect(buffers)
          events = []

          timer_buffer = buffers.find { |b| b.type == 'timer' }
          touch_buffer = buffers.find { |b| b.type == 'touch' }
          @touch_buffer = touch_buffer || @touch_buffer

          if timer_buffer &&
            timer_buffer.events.any? &&
            @last_known_gesture &&
            (timer_buffer.events.last.time - @last_known_gesture.time) > event_expire_time

            # TODO: should we also clear the touch buffer?
            events << create_event(record: @last_known_gesture.record.create_index_record(status: 'end', trigger: :repeat)) if @last_known_gesture.record.repeatable?
            @last_known_gesture = nil
          end

          if timer_buffer
            # if this is a timer tick, we have to have saved touch buffer to work with
            return events if @touch_buffer.nil? || @touch_buffer.empty?
          else
            # if not, we have to have a new touch buffer events
            return events if touch_buffer.nil? || touch_buffer.empty?
          end

          # current gesture ended or even new gesture began
          if (@touch_buffer.ended? || @touch_buffer.began?) && @last_known_gesture
            events << create_event(record: @last_known_gesture.record.create_index_record(status: 'end', trigger: :repeat)) if @last_known_gesture.record.repeatable?
            @last_known_gesture = nil
          end

          gesture_record = nil
          if touch_buffer
            @detectors.each do |detector|
              gesture_record = detector.detect(@touch_buffer)
              break if gesture_record
            end
          else
            return events if @touch_buffer.empty?
            # gesture_record = @hold_detector.detect(@touch_buffer)
          end

          if gesture_record
            @touch_buffer.clear
            if gesture_record.repeatable? && @last_known_gesture&.record == gesture_record
              @last_known_gesture = create_event(record: gesture_record)
              events << create_event(record: gesture_record.create_index_record(status: 'update', trigger: :repeat))
            else
              events << create_event(record: @last_known_gesture.record.create_index_record(status: 'end', trigger: :repeat)) if @last_known_gesture&.record&.repeatable?
              @last_known_gesture = create_event(record: gesture_record)
              events << create_event(record: gesture_record.create_index_record)
              events << create_event(record: gesture_record.create_index_record(status: 'begin', trigger: :repeat)) if gesture_record.repeatable?
            end
          end

          events
        end

        private

        def event_expire_time
          2.0 # TODO: make configurable
        end

      end # class TouchDetector
    end
  end
end
# frozen_string_literal: true

require 'spec_helper'
require 'fusuma/plugin/parsers/parser'
require 'fusuma/plugin/parsers/touch_parser'

module Fusuma
  RSpec.describe Plugin::Parsers::TouchParser do
    subject { described_class.new }

    describe '#parse' do
      it 'TOUCH_DOWN' do
        parsed = subject.parse_record(' event4   TOUCH_DOWN              +1.500s       1 (1) 49.33/47.67 (124.63/79.84mm)')
        expect(parsed.status).to eq 'begin'
        expect(parsed.finger).to eq 1
        expect(parsed.time_offset).to eq 1.5
        expect(parsed.x_px).to eq 49.33
        expect(parsed.y_px).to eq 47.67
        expect(parsed.x_mm).to eq 124.63
        expect(parsed.y_mm).to eq 79.84
      end

      it 'TOUCH_UP' do
        parsed = subject.parse_record(' event4   TOUCH_UP                +3.300s       1 (1)')
        expect(parsed.status).to eq 'end'
        expect(parsed.finger).to eq 1
        expect(parsed.time_offset).to eq 3.3
        expect(parsed.x_px).to be_nil
        expect(parsed.y_px).to be_nil
        expect(parsed.x_mm).to be_nil
        expect(parsed.y_mm).to be_nil
      end

      it 'TOUCH_MOTION' do
        parsed = subject.parse_record(' event4   TOUCH_MOTION            +2.351s       1 (1) 26.84/53.27 (67.82/89.21mm)')
        expect(parsed.status).to eq 'update'
        expect(parsed.finger).to eq 1
        expect(parsed.time_offset).to eq 2.351
        expect(parsed.x_px).to eq 26.84
        expect(parsed.y_px).to eq 53.27
        expect(parsed.x_mm).to eq 67.82
        expect(parsed.y_mm).to eq 89.21
      end

      it 'not a touch event' do
        parsed = subject.parse_record(' event4   KEYBOARD_KEY             +3.300s       1 (1)')
        expect(parsed).to be_nil
      end
    end
  end
end
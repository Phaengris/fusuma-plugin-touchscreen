# frozen_string_literal: true

require "spec_helper"
require './lib/fusuma/plugin/devices/touchscreen_device'

module Fusuma
  RSpec.describe Plugin::Touchscreen::DevicePatch do
    let(:libinput_device_command) { "dummy-libinput-list-devices" }
    before do
      Device.reset
      allow_any_instance_of(LibinputCommand)
        .to receive(:list_devices_command)
              .and_return(libinput_device_command)

      @dummy_io = StringIO.new("dummy")
      allow(Open3).to receive(:popen3)
                        .with(libinput_device_command)
                        .and_return([@dummy_io, list_devices_output, @dummy_io, nil])
    end

    # that's the only touchscreen device I have :)
    context 'Microsoft Surface 3 Pro' do
      let(:list_devices_output) do
        File.open("./spec/fixtures/libinput-list-devices_ms-surface-3-pro.txt")
      end

      it 'detects Microsoft Surface 3 Pro touchscreen' do
        expect(Device.available.map(&:name)).to include 'NTRG0001:01 1B96:1B05'
      end
    end

  end
end

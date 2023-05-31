# frozen_string_literal: true

module Fusuma
  module Plugin
    module Touchscreen
      module DevicePatch
        module ClassMethods
          def all
            @all ||= super.tap do |devices|
              devices.each do |device|
                device.assign_attributes(available: true) if device.capabilities.match?(/touch/)
              end
            end
          end
        end

        Fusuma::Device.singleton_class.prepend(ClassMethods)
      end
    end
  end
end

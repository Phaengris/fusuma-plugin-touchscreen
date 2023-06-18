# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class Base < Record
            attr_reader :finger

            def initialize(finger:)
              super()
              @finger = finger.to_i
            end

            def repeatable?
              raise NotImplementedError
            end

            def ==(other)
              return false unless other.is_a?(self.class)
              @finger == other.finger
            end

            def create_index_record(status: nil, trigger: :oneshot)
              keys = config_index_keys
              keys << Config::Index::Key.new(status) if status
              Events::Records::IndexRecord.new(index: Config::Index.new(keys), trigger: trigger)
            end

            protected

            def config_index_keys
              [
                Config::Index::Key.new(gesture_type),
                Config::Index::Key.new(@finger),
              ]
            end

            private

            def self.gesture_type
              @gesture_type ||= self.to_s.split('::').last.downcase.delete_suffix('record')
            end

            def gesture_type
              # yes, that's not a good practice, but I'm not sure if we need this method in the public interface
              self.class.send(:gesture_type)
            end

          end # class Base
        end
      end
    end
  end
end

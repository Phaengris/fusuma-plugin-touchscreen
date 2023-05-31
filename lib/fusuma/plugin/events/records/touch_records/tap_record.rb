require_relative './base'

# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class TapRecord < Base

            def initialize(finger:)
              super()
              @finger = finger
            end

            def finalized?
              true
            end

            def create_index_record
              Events::Records::IndexRecord.new(
                index: Config::Index.new(
                  [
                    Config::Index::Key.new('tap'),
                    Config::Index::Key.new(@finger)
                  ]
                )
              )
            end

          end
        end
      end
    end
  end
end
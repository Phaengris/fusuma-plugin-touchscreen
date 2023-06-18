require_relative './base'

# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class SwipeRecord < Base

            def initialize(direction:, **args)
              super(**args)
              @direction = direction.to_s
            end

            def repeatable?
              true
            end

            protected

            def config_index_keys
              super << Config::Index::Key.new(@direction)
            end


          end # class SwipeRecord
        end
      end
    end
  end
end
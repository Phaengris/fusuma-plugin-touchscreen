require_relative './base'

# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class HoldRecord < Base

            def repeatable?
              true
            end

          end # class HoldRecord
        end
      end
    end
  end
end
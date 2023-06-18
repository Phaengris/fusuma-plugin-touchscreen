require_relative './base'

# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class TapRecord < Base

            def repeatable?
              false
            end

          end # class TapRecord
        end
      end
    end
  end
end
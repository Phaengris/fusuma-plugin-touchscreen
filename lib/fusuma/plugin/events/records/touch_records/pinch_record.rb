require_relative './base'
require_relative './features/direction'

# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          class PinchRecord < Base
            prepend Features::Direction

            def repeatable?
              true
            end

          end # class PinchRecord
        end
      end
    end
  end
end
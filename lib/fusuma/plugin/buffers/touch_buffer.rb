# frozen_string_literal: true

module Fusuma
  module Plugin
    module Buffers
      class TouchBuffer < Buffer
        DEFAULT_SOURCE = "libinput_touch_parser"
        DEFAULT_SECONDS_TO_KEEP = 100

        def config_param_types
          {
            source: [String],
            seconds_to_keep: [Float, Integer]
          }
        end

        def buffer(event)
          return if event&.tag != source

          @events.push(event)
          self
        end

        def clear_expired(current_time: Time.now)
          # clear if ended?

          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)
          @events.each do |e|
            break if current_time - e.time < @seconds_to_keep

            @events.delete(e)
          end
        end

        # def ended?
        #
        # end
      end
    end
  end
end
module Fusuma
  module Plugin
    module Events
      module Records
        module TouchRecords
          module Features
            module Direction

              def self.prepended(base)
                base.class_eval do
                  attr_reader :direction
                end
              end

              def initialize(direction:, **args)
                super(**args)
                @direction = direction.to_s
              end

              def ==(other)
                super(other) && direction == other.direction
              end

              protected

              def config_index_keys
                super << Config::Index::Key.new(@direction)
              end

            end # module WithDirection
          end
        end
      end
    end
  end
end
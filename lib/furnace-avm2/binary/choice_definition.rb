module Furnace::AVM2::Binary
  class ChoiceDefinition

    include Furnace::AVM2

    def initialize
      @data = []
    end

    def self.parse(block)
      instance = new
      instance.instance_exec(&block)
      instance.to_a
    end

    def variant(value, type, sub_options={})
      @data << [ value, type, sub_options ]
    end

    def to_a
      @data
    end
  end
end

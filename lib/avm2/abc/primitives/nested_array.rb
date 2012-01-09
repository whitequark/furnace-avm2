module AVM2::ABC
  class NestedArray < BinData::Array
    attr_reader :root

    def initialize_instance
      super

      @root = parent.root if parent
    end
  end
end
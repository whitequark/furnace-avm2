module AVM2::ABC
  class IndirectlyNestedRecord < Record
    attr_reader :root

    def initialize_instance
      super

      @root = parent.parent.root if parent
    end
  end
end
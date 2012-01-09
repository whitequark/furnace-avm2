module AVM2::ABC
  class NestedRecord < Record
    attr_reader :root

    def initialize_instance
      super

      @root = parent.root if parent
    end
  end
end
module Furnace::AVM2::ABC
  class MultinameKindRTQNameL < Record
    def to_s
      "(rt)::(rt)"
    end

    def collect_ns(options)
      # nothing
    end

    def context_size
      2
    end
  end
end

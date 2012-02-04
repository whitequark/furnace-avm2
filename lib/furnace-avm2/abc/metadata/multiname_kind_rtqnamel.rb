module Furnace::AVM2::ABC
  class MultinameKindRTQNameL < Record
    def to_s
      "(rt)::(rt)"
    end

    def context_size
      2
    end
  end
end

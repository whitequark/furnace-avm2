module AVM2::ABC
  class KlassInfo < Record
    vuint30      :cinit

    abc_array_of :trait, :nested, :class => TraitInfo
  end
end

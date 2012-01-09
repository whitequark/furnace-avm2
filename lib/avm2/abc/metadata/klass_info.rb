module AVM2::ABC
  class KlassInfo < NestedRecord
    vuint30      :cinit

    abc_array_of :trait, :trait_info
  end
end

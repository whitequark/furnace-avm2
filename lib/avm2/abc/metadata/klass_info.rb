module AVM2::ABC
  class KlassInfo < Record
    root_ref     :initializer, :method

    abc_array_of :trait, :nested, :class => TraitInfo
  end
end

module AVM2::ABC
  class KlassInfo < Record
    vuint30 :cinit

    vuint30 :trait_count, :value => lambda { traits.count() }
    array   :traits, :type => :traits_info, :initial_length => :trait_count
  end
end

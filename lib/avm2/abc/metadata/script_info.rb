module AVM2::ABC
  class ScriptInfo < Record
    vuint30 :init

    vuint30 :trait_count, :value => lambda { traits.count }
    array   :traits, :type => :traits_info, :initial_length => :trait_count
  end
end

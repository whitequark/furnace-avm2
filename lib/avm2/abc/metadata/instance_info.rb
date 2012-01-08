module AVM2::ABC
  class InstanceInfo < Record
    ClassSealed      = 0x01
    ClassFinal       = 0x02
    ClassInterface   = 0x04
    ClassProtectedNs = 0x08

    vuint30 :name
    vuint30 :super_name
    uint8   :flags
    vuint30 :protectedNs, :onlyif => lambda { flags & ClassProtectedNs != 0}

    vuint30 :interface_count, :value => lambda { interfaces.count() }
    array   :interfaces, :type => :vuint30, :initial_length => :interface_count

    vuint30 :iinit

    vuint30 :trait_count, :value => lambda { traits.count() }
    array   :traits, :type => :traits_info, :initial_length => :trait_count
  end
end

module AVM2::ABC
  class InstanceInfo < Record
    CLASS_SEALED       = 0x01
    CLASS_FINAL        = 0x02
    CLASS_INTERFACE    = 0x04
    CLASS_PROTECTED_NS = 0x08

    vuint30      :name
    vuint30      :super_name
    uint8        :flags
    vuint30      :protected_ns, :if => lambda { flags & CLASS_PROTECTED_NS != 0}

    abc_array_of :interface, :vuint30

    vuint30      :iinit

    abc_array_of :trait, :nested, :class => TraitInfo
  end
end

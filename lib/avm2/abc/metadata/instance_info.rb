module AVM2::ABC
  class InstanceInfo < Record
    CLASS_SEALED       = 0x01
    CLASS_FINAL        = 0x02
    CLASS_INTERFACE    = 0x04
    CLASS_PROTECTED_NS = 0x08

    const_ref      :name,         :multiname
    const_ref      :super_name,   :multiname

    uint8          :flags
    flag           :sealed,       :flags, CLASS_SEALED
    flag           :final,        :flags, CLASS_FINAL
    flag           :interface,    :flags, CLASS_INTERFACE
    flag           :protected_ns, :flags, CLASS_PROTECTED_NS

    const_ref      :protected_ns, :namespace, :if => :protected_ns?

    const_array_of :interface,    :multiname

    root_ref       :initializer,  :method

    abc_array_of   :trait, :nested, :class => TraitInfo

    def to_astlet
      if interface?
        root = AST::Node.new(:interface)
      else
        root = AST::Node.new(:instance)
      end

      root.children << name.to_astlet

      unless interface?
        if super_name
          root.children << super_name.to_astlet
        else
          root.children << nil
        end
      end

      if interfaces.any?
        root.children << AST::Node.new(:interfaces, interfaces.map(&:to_astlet))
      end

      if traits.any?
        root.children << AST::Node.new(:traits, traits.map(&:to_astlet))
      end

      root.normalize_hierarchy!
    end
  end
end

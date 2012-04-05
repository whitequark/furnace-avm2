module Furnace::AVM2::ABC
  class InstanceInfo < Record
    include RecordWithTraits

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

    def klass
      root.klasses[root.instances.index(self)]
    end

    def initializer_body
      root.method_bodies.find { |body| body.method_idx == initializer_idx }
    end

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

      if initializer
        root.children << AST::Node.new(:initializer,
          [ initializer.to_astlet(initializer_idx, name.to_astlet) ])
      end

      if traits.any?
        root.children << AST::Node.new(:traits, traits.map(&:to_astlet))
      end

      root.normalize_hierarchy!
    end

    def collect_ns
      ns = []
      ns << super_name.ns if super_name
      ns += initializer.collect_ns if initializer
      interfaces.each   { |iface| ns << iface.ns_set.ns[0] } # stupid avm2
      traits.each       { |trait| ns += trait.collect_ns }
      klass.traits.each { |trait| ns += trait.collect_ns }
      ns
    end

    def decompile(options={})
      Furnace::AVM2::Tokens::PackageToken.new(self,
            options.merge(
                ns: collect_ns,
                package_type: (interface? ? :interface : :class),
                package_name: name))
    end
  end
end

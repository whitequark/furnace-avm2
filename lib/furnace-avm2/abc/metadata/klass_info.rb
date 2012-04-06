module Furnace::AVM2::ABC
  class KlassInfo < Record
    include RecordWithTraits
    include InitializerBody

    root_ref     :initializer, :method

    abc_array_of :trait, :nested, :class => TraitInfo

    def instance
      root.instances[root.klasses.index(self)]
    end

    def to_astlet
      root = AST::Node.new(:klass)

      if initializer
        root.children << AST::Node.new(:initializer,
          [ initializer.to_astlet(initializer_idx, instance.name.to_astlet) ])
      end

      if traits.any?
        root.children << AST::Node.new(:traits, traits.map(&:to_astlet))
      end

      root.normalize_hierarchy!
    end
  end
end

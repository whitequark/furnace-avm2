module Furnace::AVM2::ABC
  class KlassInfo < Record
    include RecordWithTraits

    root_ref     :initializer, :method

    abc_array_of :trait, :nested, :class => TraitInfo

    def to_astlet
      root = AST::Node.new(:klass)

      if traits.any?
        root.children << AST::Node.new(:traits, traits.map(&:to_astlet))
      end

      root.normalize_hierarchy!
    end
  end
end

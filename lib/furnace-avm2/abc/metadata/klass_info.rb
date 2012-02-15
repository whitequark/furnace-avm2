module Furnace::AVM2::ABC
  class KlassInfo < Record
    include RecordWithTraits

    root_ref     :initializer, :method

    abc_array_of :trait, :nested, :class => TraitInfo

    def initializer_body
      root.method_bodies.find { |body| body.method_idx == initializer_idx }
    end

    def to_astlet
      root = AST::Node.new(:klass)

      if traits.any?
        root.children << AST::Node.new(:traits, traits.map(&:to_astlet))
      end

      root.normalize_hierarchy!
    end
  end
end

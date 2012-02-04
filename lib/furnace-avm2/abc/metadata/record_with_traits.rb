module Furnace::AVM2::ABC
  module RecordWithTraits
    TraitInfo::XlatTable.keys.each do |trait_type|
      basename = trait_type.to_s.downcase

      define_method :"#{basename}_traits" do
        traits.select { |trait| trait.kind == trait_type }
      end

      define_method :"#{basename}_trait" do |name|
        case name
        when String
          traits.find { |trait| trait.name.to_s == name }
        when AST::Node
          traits.find { |trait| trait.name.to_astlet == name }
        else
          traits.find { |trait| trait.name == name }
        end
      end

      define_method :"#{basename}_trait!" do |name|
        send(:"#{basename}_trait", name) or
            raise "trait #{name} not found"
      end
    end

    def codes_to_ast
      trees = method_traits.map do |trait|
        trait.body.code_to_ast rescue nil
      end.compact
    end
  end
end
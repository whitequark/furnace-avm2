module AVM2::ABC
  module RecordWithTraits
    TraitInfo::XlatTable.keys.each do |trait_type|
      define_method :"#{trait_type.to_s.downcase}_traits" do
        traits.select { |trait| trait.kind == trait_type }
      end
    end

    def codes_to_ast
      trees = method_traits.map do |trait|
        trait.body.code_to_ast rescue nil
      end.compact
    end
  end
end
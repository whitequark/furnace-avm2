module AVM2::ABC
  class MultinameKindMultiname < Record
    const_ref :name,   :string
    const_ref :ns_set, :ns_set

    def to_s
      "#{ns_set}::#{name || '*'}"
    end

    def to_astlet
      AST::Node.new(:m, [ ns_set.to_astlet, name ])
    end

    def context_size
      0
    end
  end
end

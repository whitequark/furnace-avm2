module AVM2::ABC
  class MultinameKindMultinameL < Record
    const_ref :ns_set, :ns_set

    def to_s
      "#{ns_set}::(rt)"
    end

    def to_astlet(name)
      node = AST::Node.new(:m, [ ns_set.to_astlet, name ])
    end

    def context_size
      1
    end
  end
end

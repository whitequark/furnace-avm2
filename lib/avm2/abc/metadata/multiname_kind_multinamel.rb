module AVM2::ABC
  class MultinameKindMultinameL < Record
    const_ref :ns_set, :ns_set

    def to_s
      "#{ns_set}::(rt)"
    end
  end
end

module AVM2::ABC
  class MultinameKindMultiname < Record
    const_ref :name,   :string
    const_ref :ns_set, :ns_set

    def to_s
      "#{ns_set}::#{name || '*'}"
    end
  end
end

module AVM2::ABC
  class MultinameKindQName < Record
    const_ref :ns, :namespace
    const_ref :name, :string

    def to_s
      if ns
        "#{ns}::#{name || '*'}"
      else
        name || '*'
      end
    end
  end
end

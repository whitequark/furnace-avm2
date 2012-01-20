module AVM2::ABC
  class MultinameKindRTQName < Record
    const_ref :name, :string

    def to_s
      "(rt)::#{name || '*'}"
    end
  end
end

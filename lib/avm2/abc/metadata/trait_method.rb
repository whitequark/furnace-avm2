module AVM2::ABC
  class TraitMethod < Record
    vuint30  :disp_id
    root_ref :method

    def to_astlet(trait)
      method.to_astlet(method_idx, trait.name.to_astlet)
    end
  end
end

module AVM2::ABC
  class TraitMethod < Record
    vuint30  :disp_id
    root_ref :method

    def to_astlet(trait)
      astlet = method.to_astlet(trait.name.to_astlet)
      astlet.metadata[:label] = method_idx
      astlet
    end
  end
end

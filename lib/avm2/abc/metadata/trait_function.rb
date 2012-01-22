module AVM2::ABC
  class TraitFunction < Record
    vuint30  :slot_id
    root_ref :method

    def to_astlet(trait)
    end
  end
end

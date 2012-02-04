module Furnace::AVM2::ABC
  class TraitClass < Record
    vuint30 :slot_id
    vuint30 :classi

    def to_astlet(trait)
      :class
    end
  end
end

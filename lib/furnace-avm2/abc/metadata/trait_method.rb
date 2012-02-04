module Furnace::AVM2::ABC
  class TraitMethod < Record
    vuint30  :disp_id
    root_ref :method

    def body
      root.method_bodies.find { |body| body.method_idx == method_idx }
    end

    def to_astlet(trait)
      method.to_astlet(method_idx, trait.name.to_astlet)
    end
  end
end

module Furnace::AVM2::ABC
  class TraitMethod < Record
    vuint30  :disp_id
    root_ref :method

    def body
      root.method_body_at(method_idx)
    end

    def to_astlet(trait)
      method.to_astlet(method_idx, trait.name.to_astlet)
    end

    def collect_ns(options)
      method.collect_ns(options)
      body.collect_ns(options) if body
    end
  end
end

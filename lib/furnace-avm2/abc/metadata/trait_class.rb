module Furnace::AVM2::ABC
  class TraitClass < Record
    vuint30  :slot_id
    root_ref :klass,   :klass, :plural => :klasses

    def to_astlet(trait)
      AST::Node.new(:class, [trait.name.to_astlet, klass.instance.name.to_astlet])
    end

    def collect_ns(options)
      # dummy
    end
  end
end

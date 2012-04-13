module Furnace::AVM2::ABC
  class MultinameKindRTQName < Record
    const_ref :name, :string

    def to_s
      "(rt)::#{name || '*'}"
    end

    def to_astlet(ns)
      node = AST::Node.new(:q, [ ns, name ])
    end

    def collect_ns(options)
      # nothing
    end

    def context_size
      1
    end
  end
end

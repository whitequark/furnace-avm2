module Furnace::AVM2::ABC
  # Undocumented
  class MultinameKindGenericName < Record
    const_ref      :name,      :multiname
    const_array_of :parameter, :multiname

    def to_s
      "#{name.to_s}<#{parameters.map(&:to_s).join(",")}>"
    end

    def to_astlet
      AST::Node.new(:generic, [ name.to_astlet, parameters.map(&:to_astlet) ])
    end

    def collect_ns
      [ *name.collect_ns, *parameters.map(&:collect_ns).reduce([], :+) ]
    end
  end
end

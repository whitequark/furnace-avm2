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

    def collect_ns(options)
      name.collect_ns(options)
      parameters.each { |type| type.collect_ns(options) }
    end
  end
end

module AVM2::ABC
  # Undocumented
  class MultinameKindGenericName < Record
    vuint30      :name_type

    abc_array_of :parameter, :vuint30

    def to_s
      "(genericname)"
    end

    def to_astlet
      AST::Node.new(:generic, [ name_type, parameters ])
    end
  end
end

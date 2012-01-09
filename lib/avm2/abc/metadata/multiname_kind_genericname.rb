module AVM2::ABC
  # Undocumented
  class MultinameKindGenericname < IndirectlyNestedRecord
    vuint30      :name_type

    abc_array_of :parameter, :vuint30
  end
end

module AVM2::ABC
  # Undocumented
  class MultinameKindGenericname < BinData::Record
    vuint30  :type

    vuint30  :parameter_count,                :value => lambda { parameters.count }
    array    :parameters, :type => :vuint30, :initial_length => :parameter_count
  end
end

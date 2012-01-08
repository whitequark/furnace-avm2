module AVM2::ABC
  class MethodBodyInfo < BinData::Record
    vuint30 :method_name
    vuint30 :max_stack
    vuint30 :local_count
    vuint30 :init_scope_depth
    vuint30 :max_scope_depth

    vuint30 :code_length, :value => lambda { code.length }
    string  :code, :read_length => :code_length

    vuint30 :exception_count, :value => lambda { exceptions.count }
    array   :exceptions, :type => :exception_info, :initial_length => :exception_count

    vuint30 :trait_count, :value => lambda { traits.count }
    array   :traits, :type => :traits_info, :initial_length => :trait_count
  end
end

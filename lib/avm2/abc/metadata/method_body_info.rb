module AVM2::ABC
  class MethodBodyInfo < NestedRecord
    vuint30      :method_name
    vuint30      :max_stack
    vuint30      :local_count
    vuint30      :init_scope_depth
    vuint30      :max_scope_depth

    vuint30      :code_length, :value => lambda { code.num_bytes }
    opcode_array :code, :type => :opcode, :initial_byte_length => :code_length

    abc_array_of :exception, :exception_info

    abc_array_of :trait, :trait_info
  end
end

module AVM2::ABC
  class MethodBodyInfo < Record
    vuint30      :method_name
    vuint30      :max_stack
    vuint30      :local_count
    vuint30      :init_scope_depth
    vuint30      :max_scope_depth

    vuint30      :code_length, :value => lambda { code.byte_length }
    nested       :code, :class => OpcodeSequence

    abc_array_of :exception, :nested, :class => ExceptionInfo

    abc_array_of :trait, :nested, :class => TraitInfo
  end
end

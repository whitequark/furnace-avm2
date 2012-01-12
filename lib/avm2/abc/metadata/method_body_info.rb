module AVM2::ABC
  class MethodBodyInfo < Record
    root_ref     :method
    vuint30      :max_stack
    vuint30      :local_count
    vuint30      :init_scope_depth
    vuint30      :max_scope_depth

    vuint30      :code_length, :value => lambda { code.byte_length }
    nested       :code, :class => OpcodeSequence

    abc_array_of :exception, :nested, :class => ExceptionInfo

    abc_array_of :trait, :nested, :class => TraitInfo

    def after_read(io)
      exceptions.each do |exception|
        exception.resolve!
      end
    end
  end
end

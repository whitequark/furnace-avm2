module Furnace::AVM2::ABC
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

    def code_to_ast
      unless @ast
        pipeline = Furnace::Transform::Pipeline.new([
          Furnace::AVM2::Transform::ASTBuild.new(validate: true),
          Furnace::AVM2::Transform::ASTNormalize.new
        ])

        @ast, = pipeline.run(code, self)
      end

      @ast
    end

    def decompile(options={})
      Furnace::AVM2::Tokens::FunctionBodyToken.new(self, options)
    end
  end
end
module Furnace::AVM2::ABC
  class MethodBodyInfo < Record
    include RecordWithTraits

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

    def code_to_ast(options={ eliminate_nops: true })
      pipeline = Furnace::Transform::Pipeline.new([
        Furnace::AVM2::Transform::ASTBuild.new(options),
        Furnace::AVM2::Transform::ASTNormalize.new(options),
        Furnace::AVM2::Transform::PropagateConstants.new,
      ])

      pipeline.run(code, self)
    end

    def code_to_cfg
      pipeline = Furnace::Transform::Pipeline.new([
        Furnace::AVM2::Transform::PropagateLabels.new,
        Furnace::AVM2::Transform::CFGBuild.new
      ])

      pipeline.run(*code_to_ast({}))
    end

    def code_to_nf
      pipeline = Furnace::Transform::Pipeline.new([
        Furnace::AVM2::Transform::CFGReduce.new,
        Furnace::AVM2::Transform::NFNormalize.new,
      ])

      pipeline.run(*code_to_cfg)
    end

    def decompile(options={})
      Furnace::AVM2::Decompiler.new(self, options).decompile
    end

    def collect_ns(options)
      code.each do |opcode|
        opcode.collect_ns(options) if opcode.respond_to? :collect_ns
      end
    end
  end
end
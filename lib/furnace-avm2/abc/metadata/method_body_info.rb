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

    def code_to_cfg(options={})
      pipeline = Furnace::Transform::Pipeline.new([
        Furnace::AVM2::Transform::CFGBuild.new,
        Furnace::AVM2::Transform::SSATransform.new,
        Furnace::AVM2::Transform::RefineLocalVariableBarriers.new,
        Furnace::AVM2::Transform::SSAOptimize.new(idempotent: true),

        Furnace::Transform::IterativeProcess.new([
          Furnace::AVM2::Transform::DataflowInvariantCodeMotion.new,
          Furnace::AVM2::Transform::PartialEvaluation.new,
          Furnace::AVM2::Transform::SSAOptimize.new,

          Furnace::AVM2::Transform::FoldBooleanShortcuts.new,
          Furnace::AVM2::Transform::FoldTernaryOperators.new,
          Furnace::AVM2::Transform::FoldIncrementDecrement.new,
          Furnace::AVM2::Transform::SSAOptimize.new,
        ]),

        Furnace::AVM2::Transform::FoldPassthroughAssignments.new,
=begin
        Furnace::AVM2::Transform::ConvertLocalsToSSA.new,
        Furnace::Transform::IterativeProcess.new([
          Furnace::AVM2::Transform::DataflowInvariantCodeMotion.new,
          Furnace::AVM2::Transform::PartialEvaluation.new,
          Furnace::AVM2::Transform::SSAOptimize.new,
        ]),
=end
        Furnace::AVM2::Transform::PropagateConstants.new,

        Furnace::AVM2::Transform::ExpandUnreferencedSets.new,
        Furnace::AVM2::Transform::UpdateExceptionVariables.new,
      ])

      pipeline.run(code, self)
    end

    def code_to_nf(options={})
      pipeline = Furnace::Transform::Pipeline.new([
        Furnace::AVM2::Transform::CFGReduce.new,
        Furnace::AVM2::Transform::NFNormalize.new(method: method),
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
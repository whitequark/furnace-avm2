module Furnace::AVM2::ABC
  class ExceptionInfo < Record
    vuint30   :from_offset
    vuint30   :to_offset
    vuint30   :target_offset

    const_ref :exception, :multiname
    const_ref :variable,  :multiname

    attr_reader :from, :to, :target

    def initialize_record(options)
      @parent = options[:parent]
    end

    def resolve!
      sequence = @parent.code

      @from   = sequence.opcode_at(from_offset)
      @to     = sequence.opcode_at(to_offset)
      @target = sequence.opcode_at(target_offset)
    end

    def lookup!
      # HACK ALERT this fixes improper DCE implementation failures
      self.from_offset   = @from.offset    || 0
      self.to_offset     = @to.offset      || 0
      self.target_offset = @target.offset  || 0
    end

    def range
      from_offset..to_offset
    end
  end
end

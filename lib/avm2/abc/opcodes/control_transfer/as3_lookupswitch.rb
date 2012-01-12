module AVM2::ABC
  class AS3LookupSwitch < Opcode
    instruction 0x1b

    body do
      int24   :default_offset
      vuint30 :case_count,   :value => lambda { case_offsets.count - 1 }
      array   :case_offsets, :type => :int24, :initial_length => lambda { case_count + 1 }
    end

    consume 1
    produce 0

    attr_accessor :default_target, :case_targets

    def resolve!
      @default_target = @sequence.opcode_at(offset + body.default_offset)
      @case_targets = body.case_offsets.map do |case_offset|
        @sequence.opcode_at(offset + case_offset)
      end
    end

    def lookup!
      body.default_offset = @default_target.offset - offset
      body.case_offsets = @case_targets.map do |case_target|
        case_target.offset - offset
      end
    end
  end
end
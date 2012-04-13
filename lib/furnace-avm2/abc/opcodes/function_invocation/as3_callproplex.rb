module Furnace::AVM2::ABC
  class AS3CallPropertyLex < Opcode
    include ContextualOpcode

    instruction 0x4c

    implicit_operand false

    body do
      const_ref :property, :multiname
      vuint30   :arg_count
    end

    consume { body.arg_count }
    produce 1

    def disassemble_parameters
      "#{body.property.to_s}(#{body.arg_count})"
    end

    def collect_ns(options)
      body.property.collect_ns(options)
    end
  end
end
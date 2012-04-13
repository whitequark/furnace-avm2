module Furnace::AVM2::ABC
  class AS3ConstructProperty < Opcode
    include ContextualOpcode

    instruction 0x4a

    body do
      const_ref :property, :multiname
      vuint30   :arg_count
    end

    implicit_operand false
    consume { body.arg_count }
    produce 1

    def disassemble_parameters
      "#{body.property} #{body.arg_count}"
    end

    def collect_ns(options)
      body.property.collect_ns(options)
    end
  end
end
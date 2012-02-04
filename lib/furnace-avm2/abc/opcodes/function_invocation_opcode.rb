module Furnace::AVM2::ABC
  class FunctionInvocationOpcode < Opcode
    include ContextualOpcode

    body do
      const_ref :property, :multiname
      vuint30   :arg_count
    end

    implicit_operand false
    consume { body.arg_count }

    def disassemble_parameters
      "#{body.property} #{body.arg_count}"
    end
  end
end
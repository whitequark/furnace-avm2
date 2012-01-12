module AVM2::ABC
  class AS3CallPropVoid < Opcode
    instruction 0x4f

    body do
      const_ref :property, :multiname
      vuint30   :arg_count
    end

    consume nil # TODO
    produce 0

    def disassemble_parameters
      "#{body.property} (#{body.arg_count})"
    end
  end
end
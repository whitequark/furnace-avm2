module AVM2::ABC
  class AS3InitProperty < Opcode
    instruction 0x68

    body do
      const_ref :property, :multiname
    end

    consume nil # TODO
    produce 0

    def disassemble_parameters
      "#{body.property}"
    end
  end
end
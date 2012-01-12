module AVM2::ABC
  class AS3CallSuper < Opcode
    instruction 0x45

    body do
      const_ref :property, :multiname
      vuint30   :arg_count
    end

    consume nil # TODO
    produce 1

    def disassemble_parameters
      "#{body.property} (#{body.arg_count})"
    end
  end
end
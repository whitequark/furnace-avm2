module AVM2::ABC
  class PropertyOpcode < Opcode
    include ContextualOpcode

    body do
      const_ref :property, :multiname
    end

    def disassemble_parameters
      body.property.to_s
    end
  end
end
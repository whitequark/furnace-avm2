module Furnace::AVM2::ABC
  class PropertyOpcode < Opcode
    include ContextualOpcode

    body do
      const_ref :property, :multiname
    end

    def disassemble_parameters
      body.property.to_s
    end

    def collect_ns(options)
      body.property.collect_ns(options)
    end
  end
end
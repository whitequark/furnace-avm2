module Furnace::AVM2::ABC
  class AS3GetLex < Opcode
    instruction 0x60
    read_barrier  :scope
    write_barrier :memory

    body do
      const_ref :property, :multiname
    end

    consume 0
    produce 1

    def parameters
      [ body.property.to_astlet ]
    end

    def collect_ns(options)
      body.property.collect_ns(options)
    end
  end
end
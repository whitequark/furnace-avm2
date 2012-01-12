module AVM2::ABC
  class AS3CallSuper < Opcode
    instruction 0x45

    body do
      vuint30 :property_index
      vuint30 :arg_count
    end

    consume nil # TODO
    produce 1
  end
end
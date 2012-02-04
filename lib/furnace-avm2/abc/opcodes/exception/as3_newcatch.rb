module Furnace::AVM2::ABC
  class AS3NewCatch < ExceptionOpcode
    instruction 0x5a

    body do
      vuint30 :catch_index
    end

    consume 0
    produce 1

    def parameters
      [ body.catch_index ]
    end
  end
end
module AVM2::ABC
  class AS3PushUndefined < PushLiteralOpcode
    instruction 0x21

    type :undefined
  end
end
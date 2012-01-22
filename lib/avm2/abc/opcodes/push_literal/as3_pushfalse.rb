module AVM2::ABC
  class AS3PushFalse < PushLiteralOpcode
    instruction 0x27

    type :false
  end
end
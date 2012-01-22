module AVM2::ABC
  class AS3PushTrue < PushLiteralOpcode
    instruction 0x26

    type :true
  end
end
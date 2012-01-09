module AVM2::ABC
  class AS3LookupSwitch < Opcode
    instruction 0x1b
    int24   :default_offset
    vuint30 :case_count, :value => lambda { case_offsets.count - 1 }
    array   :case_offsets, :type => :int24, :initial_length => lambda { case_count + 1 }

    consume 1
    produce 0
  end
end
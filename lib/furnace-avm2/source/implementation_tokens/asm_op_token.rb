module Furnace::AVM2::Tokens
  class AsmOpToken < Furnace::Code::TerminalToken

    def initialize(origin, opcode, options={})
      super(origin, options)
      @opcode = opcode
    end

    def to_text
      "op(0x#{@opcode.opcode})"
    end
  end
end

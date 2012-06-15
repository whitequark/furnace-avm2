require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class CatchToken < ControlFlowToken
    def keyword
      "catch"
    end
  end
end
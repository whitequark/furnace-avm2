require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class SwitchToken < ControlFlowToken
    def keyword
      'switch'
    end
  end
end
require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class WithToken < ControlFlowToken
    def keyword
      'with'
    end
  end
end
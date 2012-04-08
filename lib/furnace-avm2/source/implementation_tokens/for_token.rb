require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class ForToken < ControlFlowToken
    def keyword
      'for'
    end
  end
end
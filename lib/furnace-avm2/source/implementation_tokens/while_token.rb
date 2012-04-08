require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class WhileToken < ControlFlowToken
    def keyword
      'while'
    end
  end
end
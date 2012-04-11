require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class ForEachToken < ControlFlowToken
    def keyword
      'for each'
    end
  end
end
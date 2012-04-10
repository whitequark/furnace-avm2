require_relative 'control_transfer_token'

module Furnace::AVM2::Tokens
  class BreakToken < ControlTransferToken
    def keyword
      'break'
    end
  end
end
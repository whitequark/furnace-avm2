require_relative 'control_transfer_token'

module Furnace::AVM2::Tokens
  class ContinueToken < ControlTransferToken
    def keyword
      'continue'
    end
  end
end
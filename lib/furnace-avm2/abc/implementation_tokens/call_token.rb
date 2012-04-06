module Furnace::AVM2::Tokens
  class CallToken < Furnace::Code::NonterminalToken
    include IsEmbedded
    include IsSimple
  end
end
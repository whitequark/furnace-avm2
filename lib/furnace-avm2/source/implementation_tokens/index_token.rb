module Furnace::AVM2::Tokens
  class IndexToken < Furnace::Code::NonterminalToken
    include IsSimple

    def to_text
      "#{@children[0].to_text}[#{@children[1].to_text}]"
    end
  end
end
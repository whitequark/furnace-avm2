module Furnace::AVM2::Tokens
  class TernaryOperatorToken < Furnace::Code::NonterminalToken
    include IsComplex

    def to_text
      "#{@children[0].to_text} ? #{@children[1].to_text} : #{@children[2].to_text}"
    end

    def to_structure
      structurize "... ? ... : ..."
    end
  end
end
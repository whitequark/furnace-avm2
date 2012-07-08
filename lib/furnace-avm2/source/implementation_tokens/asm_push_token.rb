module Furnace::AVM2::Tokens
  class AsmPushToken < Furnace::Code::SurroundedToken
    include IsComplex

    def text_before
      'push('
    end

    def text_after
      ')'
    end
  end
end
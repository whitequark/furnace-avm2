module Furnace::AVM2::Tokens
  class AssignmentToken < Furnace::Code::SeparatedToken
    include IsComplex

    def text_between
      " = "
    end
  end
end
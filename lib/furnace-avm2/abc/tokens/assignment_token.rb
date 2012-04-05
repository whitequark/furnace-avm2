module Furnace::AVM2::Tokens
  class AssignmentToken < Furnace::Code::SurroundedToken
    def text_before
      " = "
    end
  end
end
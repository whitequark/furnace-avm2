module Furnace::AVM2::Tokens
  class ReturnToken < Furnace::Code::SurroundedToken

    def text_before
      if @children.any?
        "return "
      else
        "return"
      end
    end

    def text_after
      ";\n"
    end
  end
end
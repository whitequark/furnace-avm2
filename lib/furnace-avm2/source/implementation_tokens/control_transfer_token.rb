module Furnace::AVM2::Tokens
  class ControlTransferToken < Furnace::Code::SurroundedToken

    def keyword
      raise "reimplement ControlTransferToken#keyword in a subclass"
    end

    def text_before
      if @children.any?
        "#{keyword} "
      else
        "#{keyword}"
      end
    end

    def text_after
      ";\n"
    end
  end
end
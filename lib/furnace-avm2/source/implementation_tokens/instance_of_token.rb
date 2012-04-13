module Furnace::AVM2::Tokens
  class InstanceOfToken < Furnace::Code::SeparatedToken
    include IsComplex

    def text_between
      " instanceof "
    end
  end
end
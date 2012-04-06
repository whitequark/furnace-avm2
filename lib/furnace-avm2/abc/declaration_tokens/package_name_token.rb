module Furnace::AVM2::Tokens
  class PackageNameToken < Furnace::Code::SurroundedToken
    def initialize(origin, name, options={})
      super(origin, [
        NamespaceNameToken.new(origin, name, options)
      ], options)
    end

    def text_before
      "package "
    end

    def text_after
      " "
    end
  end
end
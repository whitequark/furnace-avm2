module Furnace::AVM2::Tokens
  class ImportToken < Furnace::Code::SurroundedToken
    def initialize(origin, name, options={})
      super(origin, [
        NamespaceNameToken.new(origin, name, options)
      ], options)
    end

    def text_before
      "import "
    end

    def text_after
      ".*;\n"
    end
  end
end
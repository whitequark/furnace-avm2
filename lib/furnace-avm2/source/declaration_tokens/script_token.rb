module Furnace::AVM2::Tokens
  class ScriptToken < Furnace::Code::NonterminalToken
    include TokenWithTraits

    def initialize(origin, options={})
      options = options.merge(environment: :script)

      global_code = Furnace::AVM2::Decompiler.new(origin.initializer_body,
              options.merge(global_code: true)).decompile

      super(origin, [
        *transform_traits(origin, options.merge(static: false)),
        (global_code if global_code.children.any?)
      ], options)

      if options[:debug_funids] && global_code.children.any?
        @children.unshift \
          CommentToken.new(origin,
            "Function ##{origin.initializer_idx}",
          options)
      end
    end
  end
end
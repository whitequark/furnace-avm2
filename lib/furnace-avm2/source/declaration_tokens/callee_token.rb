module Furnace::AVM2::Tokens
  class CalleeToken < Furnace::Code::SurroundedToken
    def initialize(origin, header, method, body, options={})
      @method, @body = method, body

      super(origin, [
        *header,
        *declaration(origin, options),
        (Furnace::AVM2::Decompiler.new(@body,
                options).decompile if @body),
        (Furnace::Code::NewlineToken.new(origin,
                options) if @body && !options[:closure])
      ], options)

      if options[:debug_funids]
        if options[:closure]
          @children.unshift \
            SupplementaryCommentToken.new(origin,
              "Method ##{options[:index]}",
              [],
            options)
        else
          @children.unshift \
            CommentToken.new(origin,
              "Method ##{options[:index]}",
            options)
        end
      end
    end

    def text_after
      if @body.nil?
        ";\n" # no bodies
      end
    end

    def declaration(origin, options)
      if @method.has_defaults?
        defaults = [nil] * (@method.param_count - @method.default_count) + @method.defaults
      end

      args = @method.param_count.times.map do |num|
        if @method.has_param_names?
          name = @method.param_names[num]
        else
          name = "param#{num}"
        end

        if defaults
          default = defaults[num]
        end

        ArgumentDeclarationToken.new(@origin, [
          VariableNameToken.new(origin, name, options),
          (TypeToken.new(origin, [
            MultinameToken.new(origin, @method.param_types[num], options)
          ], options) if @method.param_types[num]),
          (InitializationToken.new(origin, [
            ImmediateToken.new(origin, default.printable_value, options)
          ], options) if default && default.printable_value)
        ], options)
      end

      if @method.needs_rest?
        args << ArgumentDeclarationToken.new(origin, [
          RestArgumentToken.new(origin, "local0", options)
        ], options)
      end

      tokens = []

      tokens << ArgumentsToken.new(origin, args, options)

      if @method.return_type && !options[:closure]
        tokens << TypeToken.new(origin, [
          MultinameToken.new(origin, @method.return_type, options)
        ], options)
      end

      tokens
    end
  end
end
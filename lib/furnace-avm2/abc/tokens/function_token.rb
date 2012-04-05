module Furnace::AVM2::Tokens
  class FunctionToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      if options[:type] == :constructor
        specifiers = SpecifiersToken.new(origin, options)
      else
        specifiers = FunctionSpecifiersToken.new(origin, options)
      end

      super(origin, [
        specifiers,
        FunctionNameToken.new(origin, options),
        *transform_attributes(origin, options),
        (FunctionBodyToken.new(origin, options) unless options[:package_type] == :interface)
      ], options)
    end

    def text_after
      if @options[:package_type] == :interface
        ";\n" # no bodies
      end
    end

    def transform_attributes(origin, options)
      if options[:type] == :constructor
        method = origin.initializer
      else
        method = origin.data.method
      end

      if method.has_defaults?
        defaults = [nil] * (method.param_count - method.default_count) + method.defaults
      end

      args = method.param_count.times.map do |num|
        if method.has_param_names?
          name = method.param_names[num]
        else
          name = "param#{num}"
        end

        if defaults
          default = defaults[num]
        end

        ArgumentDeclarationToken.new(@origin, [
          VariableNameToken.new(origin, name, options),
          (TypeToken.new(@origin, method.param_types[num], options) if method.param_types[num]),
          (AssignmentToken.new(origin, [
            VariableValueToken.new(origin, default.printable_value, options)
          ], options) if default && default.printable_value)
        ], options)
      end

      if method.needs_rest?
        args << ArgumentDeclarationToken.new(origin, [
          RestVariableNameToken.new(origin, "rest", options)
        ], options)
      end

      tokens = []

      tokens << ArgumentsToken.new(origin, args, options)
      if method.return_type
        tokens << TypeToken.new(origin, method.return_type, options)
      end

      tokens
    end
  end
end
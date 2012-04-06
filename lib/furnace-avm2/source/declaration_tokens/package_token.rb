module Furnace::AVM2::Tokens
  class PackageToken < Furnace::Code::NonterminalToken
    def initialize(origin, options={})
      options[:ns] = options[:ns].uniq.reject { |ns|
        ns.name == "" || ns.name == "*"
      }

      import_ns = options[:ns]

      if options[:package_name]
        options[:ns] = (options[:ns] + [ options[:package_name].ns ]).uniq
      end

      super(origin, [
        (PackageNameToken.new(origin, options[:package_name].ns.name, options) if options[:package_name]),
        ScopeToken.new(origin, [
          *import_ns.map { |ns|
            ImportToken.new(origin, ns.name, options)
          },
          (Furnace::Code::NewlineToken.new(origin, options) if import_ns.any?),
          (case options[:package_type]
           when :class;  ClassToken.new(origin, options)
           when :script; ScriptToken.new(origin, options)
           end)
        ], options)
      ], options)
    end
  end
end
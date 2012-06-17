module Furnace::AVM2::Tokens
  class PackageToken < Furnace::Code::NonterminalToken
    def initialize(origin, options={})
      options[:ns] = options[:ns].reject { |ns|
        ns.name == "" || ns.name == "*"
      }

      import_ns = options[:ns].reject { |ns|
        ns.name == options[:package_name].ns.name ||
          ns.name == "__AS3__.vec" ||
          ns.name !~ /^[A-Za-z0-9_$.]+$/
      }

      case options[:package_type]
      when :class, :interface
        content = ClassToken.new(origin, options)
      when :script
        content = ScriptToken.new(origin, options)
      end

      scope = nil
      if content.children.any?
        scope = ScopeToken.new(origin, [
          *import_ns.map { |ns|
            ImportToken.new(origin, ns.name, options)
          },
          (Furnace::Code::NewlineToken.new(origin, options) if import_ns.any?),
          content
        ], options)
      end

      super(origin, [
        (PackageNameToken.new(origin, options[:package_name].ns.name, options) if options[:package_name]),
        scope,
      ], options)
    end
  end
end
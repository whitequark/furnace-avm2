module Furnace::AVM2::Tokens
  class MultinameToken < Furnace::Code::TerminalToken
    def initialize(origin, multiname, options={})
      super(origin, options)
      @multiname = multiname
    end

    def to_text
      name_to_text(@multiname)
    end

    protected

    def name_to_text(multiname)
      if multiname
        if @options[:debug_names]
          debug = "/* #{multiname.to_astlet.to_sexp} */ "
        end

        qualified_name = ->(ns, name) {
          if @options[:ns].include?(ns) ||
                ["*", ""].include?(ns.name) ||
                @options[:omit_ns]
            "#{debug}#{name}"
          else
            "#{debug}#{ns.name}.#{name}"
          end
        }

        case multiname.kind
        when :QName, :QNameA
          qualified_name.(multiname.ns, multiname.name)
        when :GenericName
          parameters = multiname.parameters.map do |param|
            subname = name_to_text(param)
            # Fuck you.
            subname = "#{subname} " if subname.end_with? ">"
            subname
          end
          "#{debug}#{multiname.name.name}.<#{parameters.join(", ")}>"
        when :Multiname
          if multiname.ns_set.ns.count == 1
            qualified_name.(multiname.ns_set.ns[0], multiname.name)
          else
            "/* #{multiname.to_astlet.to_sexp} */ " +
                qualified_name.(multiname.ns_set.ns[0], multiname.name)
          end
        else
          "#{debug}%%#{multiname.kind}"
        end
      else
        "%%nil"
      end
    end
  end
end
module Furnace::AVM2::Tokens
  class MultinameToken < Furnace::Code::TerminalToken
    def initialize(origin, multiname, options={})
      super(origin, options)
      @multiname = multiname
    end

    def to_text
      if @multiname
        if @options[:debug_names]
          debug = "/* #{@multiname.to_astlet.to_sexp} */ "
        end

        qualified_name = ->(ns) {
          if @options[:ns].include?(ns) || ["*", ""].include?(ns.name.to_s) || @options[:omit_ns]
            "#{debug}#{@multiname.name}"
          else
            "#{debug}#{ns.name}.#{@multiname.name}"
          end
        }

        case @multiname.kind
        when :QName, :QNameA
          qualified_name.(@multiname.ns)
        when :GenericName
          "#{debug}#{@multiname.name.name}.<#{@multiname.parameters.map(&:name).join}>"
        when :Multiname
          if @multiname.ns_set.ns.count == 1
            qualified_name.(@multiname.ns_set.ns[0])
          else
            "#{debug}%%Multiname"
          end
        else
          "#{debug}%%#{@multiname.kind}"
        end
      else
        "%%nil"
      end
    end
  end
end
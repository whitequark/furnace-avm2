module Furnace::AVM2::Tokens
  class SpecifiersToken < Furnace::Code::TerminalToken
    def specifiers
      list = []
      list << "static" if @options[:static]

      if @origin.name.ns.name == ""
        list << "public"
      elsif @options[:instance]
        if @options[:instance].protected_ns? &&
              # protected_ns is not singleton. Why? Fuck me if I know.
              @origin.name.ns.name == @options[:instance].protected_ns.name
          list << "protected"
        elsif @origin.name.ns != @options[:instance].name.ns
          list << "private"
        end
      end

      list
    end

    def to_text
      list = specifiers

      if list.any?
        "#{list.join(" ")} "
      else
        ""
      end
    end
  end
end
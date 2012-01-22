module AVM2::ABC
  module ContextualOpcode
    def self.included(klass)
      klass.class_exec do
        define_property(:implicit_operand) do |value|
          if value
            consume_context { body.property.context_size }
          else
            consume_context { 1 + body.property.context_size }
          end
        end
      end
    end

    def context(content)
      case body.property.kind
      when :QName, :QNameA, :Multiname, :MultinameA
        content.push body.property.to_astlet
      when :MultinameL, :MultinameLA
        name = content.pop
        content.push body.property.to_astlet(name)
      when :RTQName, :RTQNameA
        ns = content.pop
        content.push body.property.to_astlet(ns)
      else
        raise "unsupported context #{body.property.kind}"
      end

      content
    end
  end
end
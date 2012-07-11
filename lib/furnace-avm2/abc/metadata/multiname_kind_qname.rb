module Furnace::AVM2::ABC
  class MultinameKindQName < Record
    const_ref :ns,   :namespace
    const_ref :name, :string

    def to_s
      if ns
        "#{ns}::#{name || '*'}"
      else
        name || '*'
      end
    end

    def to_astlet
      node = AST::Node.new(:q, [])

      if ns && ns.name == ""
      elsif ns
        node.children << ns.name
      else
        node.children << "*"
      end

      node.children << name

      node
    end

    def to_astpat(type=:qname)
      case type
      when :qname
        [ :q, (ns.name if ns && !ns.name.empty?), name ].compact
      when :multiname
        [ :m, [ :set, ns.name ], name ]
      else
        raise "unknown astpat type #{type}"
      end
    end

    def collect_ns(options)
      return if options[:no_ns].include?(ns)

      names = options[:names]
      if names[name].nil?
        options[:ns].add ns if ns
        names[name] = ns
      elsif names[name] != ns
        options[:no_ns].add ns if ns
      end
    end

    def context_size
      0
    end
  end
end

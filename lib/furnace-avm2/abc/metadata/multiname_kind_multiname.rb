module Furnace::AVM2::ABC
  class MultinameKindMultiname < Record
    const_ref :name,   :string
    const_ref :ns_set, :ns_set

    def to_s
      "#{ns_set}::#{name || '*'}"
    end

    def to_astlet
      AST::Node.new(:m, [ ns_set.to_astlet, name ])
    end

    def collect_ns(options)
      ns = ns_set.ns[0]
      return if options[:no_ns].include?(ns)

      names = options[:names]
      if names[name].nil?
        options[:ns].add ns
        names[name] = ns
      elsif names[name] != ns
        options[:no_ns].add ns
      end
    end

    def context_size
      0
    end
  end
end

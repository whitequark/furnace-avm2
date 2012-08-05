module Furnace::AVM2::ABC
  class NsSetInfo < Record
    const_array_of :ns, :namespace, :plural => :ns

    def to_s
      "{...,#{ns.map(&:to_s).last}}"
    end

    def to_astlet
      AST::Node.new(:set, ns.map(&:name).uniq, ellipsis: true)
    end
  end
end

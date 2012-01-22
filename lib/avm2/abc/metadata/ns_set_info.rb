module AVM2::ABC
  class NsSetInfo < Record
    const_array_of :ns, :namespace, :plural => :ns

    def to_s
      "{#{ns.map(&:to_s).join(",")}}"
    end

    def to_astlet
      ns.map(&:name).uniq
    end
  end
end

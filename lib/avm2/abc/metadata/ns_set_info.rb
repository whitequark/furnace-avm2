module AVM2::ABC
  class NsSetInfo < Record
    abc_array_of :ns, :vuint30, :plural => :ns
  end
end

module AVM2::ABC
  class NsSetInfo < BinData::Record
    vuint30  :ns_count,               :value => lambda { ns.count }
    array    :ns, :type => :vuint30, :initial_length => :ns_count
  end
end

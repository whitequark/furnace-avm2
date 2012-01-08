module AVM2::ABC
  class NamespaceInfo < Record
    uint8    :kind
    vuint30  :name
  end
end
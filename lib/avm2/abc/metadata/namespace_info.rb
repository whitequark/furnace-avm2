module AVM2::ABC
  class NamespaceInfo < NestedRecord
    uint8    :kind
    vuint30  :name
  end
end
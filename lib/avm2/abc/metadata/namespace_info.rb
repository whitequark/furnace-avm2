module AVM2::ABC
  class NamespaceInfo < NestedRecord
    XlatTable = {
      :Namespace          => 0x08,
      :PackageNamespace   => 0x16,
      :PackageInternalNs  => 0x17,
      :ProtectedNamespace => 0x18,
      :ExplicitNamespace  => 0x19,
      :StaticProtectedNs  => 0x1A,
      :PrivateNs          => 0x05,
    }

    xlat_uint8 :kind
    const_ref  :name, :string
  end
end
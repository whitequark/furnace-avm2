module AVM2::ABC
  class NamespaceInfo < Record
    XlatTable = {
      :Namespace          => 0x08,
      :PackageNamespace   => 0x16,
      :PackageInternalNs  => 0x17,
      :ProtectedNamespace => 0x18,
      :ExplicitNamespace  => 0x19,
      :StaticProtectedNs  => 0x1A,
      :PrivateNs          => 0x05,
    }

    uint8      :kind_raw
    xlat_field :kind

    const_ref  :name, :string
  end
end
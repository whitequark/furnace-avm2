module AVM2::ABC
  class OptionDetail < Record
    Int                = 0x03
    UInt               = 0x04
    Double             = 0x06
    Utf8               = 0x01
    True               = 0x0B
    False              = 0x0A
    Null               = 0x0C
    Undefined          = 0x00
    Namespace          = 0x08
    PackageNamespace   = 0x16
    PackageInternalNs  = 0x17
    ProtectedNamespace = 0x18
    ExplicitNamespace  = 0x19
    StaticProtectedNs  = 0x1A
    PrivateNs          = 0x05

    vuint30 :val
    uint8   :kind
  end
end

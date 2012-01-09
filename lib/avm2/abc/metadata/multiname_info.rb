module AVM2::ABC
  class MultinameInfo < NestedRecord
    XlatTable = {
      :QName       => 0x07,
      :QNameA      => 0x0D,
      :RTQName     => 0x0F,
      :RTQNameA    => 0x10,
      :RTQNameL    => 0x11,
      :RTQNameLA   => 0x12,
      :Multiname   => 0x09,
      :MultinameA  => 0x0E,
      :MultinameL  => 0x1B,
      :MultinameLA => 0x1C,
      :GenericName => 0x1D # Undocumented
    }

    xlat_uint8 :kind
    choice     :data, :selection => :kind do
      multiname_kind_qname       XlatTable[:QName]
      multiname_kind_qname       XlatTable[:QNameA]
      multiname_kind_rtqname     XlatTable[:RTQName]
      multiname_kind_rtqname     XlatTable[:RTQNameA]
      multiname_kind_rtqnamel    XlatTable[:RTQNameL]
      multiname_kind_rtqnamel    XlatTable[:RTQNameLA]
      multiname_kind_multiname   XlatTable[:Multiname]
      multiname_kind_multiname   XlatTable[:MultinameA]
      multiname_kind_multinamel  XlatTable[:MultinameL]
      multiname_kind_multinamel  XlatTable[:MultinameLA]
      multiname_kind_genericname XlatTable[:GenericName] # Undocumented
    end
  end
end

module AVM2::ABC
  class MultinameInfo < BinData::Record
    Kinds = {
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

    uint8  :kind, :check_value => lambda { Kinds.values.include? value }
    choice :data, :selection => :kind do
      multiname_kind_qname       Kinds[:QName]
      multiname_kind_qname       Kinds[:QNameA]
      multiname_kind_rtqname     Kinds[:RTQName]
      multiname_kind_rtqname     Kinds[:RTQNameA]
      multiname_kind_rtqnamel    Kinds[:RTQNameL]
      multiname_kind_rtqnamel    Kinds[:RTQNameLA]
      multiname_kind_multiname   Kinds[:Multiname]
      multiname_kind_multiname   Kinds[:MultinameA]
      multiname_kind_multinamel  Kinds[:MultinameL]
      multiname_kind_multinamel  Kinds[:MultinameLA]
      multiname_kind_genericname Kinds[:GenericName] # Undocumented
    end
  end
end

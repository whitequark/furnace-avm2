module AVM2::ABC
  class MultinameInfo < Record
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

    constant_table Kinds

    uint8  :kind, :check_value => lambda { Kinds.values.include? value }
    choice :data, :selection => :kind do
      multiname_kind_qname       QName
      multiname_kind_qname       QNameA
      multiname_kind_rtqname     RTQName
      multiname_kind_rtqname     RTQNameA
      multiname_kind_rtqnamel    RTQNameL
      multiname_kind_rtqnamel    RTQNameLA
      multiname_kind_multiname   Multiname
      multiname_kind_multiname   MultinameA
      multiname_kind_multinamel  MultinameL
      multiname_kind_multinamel  MultinameLA
      multiname_kind_genericname GenericName # Undocumented
    end
  end
end

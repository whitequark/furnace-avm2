module Furnace::AVM2::ABC
  class MultinameInfo < Record
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

    uint8      :kind_raw
    xlat_field :kind

    choice     :data, :selection => :kind do
      variant :QName,       :nested, :class => MultinameKindQName
      variant :QNameA,      :nested, :class => MultinameKindQName
      variant :RTQName,     :nested, :class => MultinameKindRTQName
      variant :RTQNameA,    :nested, :class => MultinameKindRTQName
      variant :RTQNameL,    :nested, :class => MultinameKindRTQNameL
      variant :RTQNameLA,   :nested, :class => MultinameKindRTQNameL
      variant :Multiname,   :nested, :class => MultinameKindMultiname
      variant :MultinameA,  :nested, :class => MultinameKindMultiname
      variant :MultinameL,  :nested, :class => MultinameKindMultinameL
      variant :MultinameLA, :nested, :class => MultinameKindMultinameL
      variant :GenericName, :nested, :class => MultinameKindGenericName
    end

    def method_missing(method, *args, &block)
      data.send(method, *args, &block)
    end

    def to_s
      data.to_s
    end
  end
end

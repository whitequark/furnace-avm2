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
      variant :QName,       :nested, :class => ABC::MultinameKindQName
      variant :QNameA,      :nested, :class => ABC::MultinameKindQName
      variant :RTQName,     :nested, :class => ABC::MultinameKindRTQName
      variant :RTQNameA,    :nested, :class => ABC::MultinameKindRTQName
      variant :RTQNameL,    :nested, :class => ABC::MultinameKindRTQNameL
      variant :RTQNameLA,   :nested, :class => ABC::MultinameKindRTQNameL
      variant :Multiname,   :nested, :class => ABC::MultinameKindMultiname
      variant :MultinameA,  :nested, :class => ABC::MultinameKindMultiname
      variant :MultinameL,  :nested, :class => ABC::MultinameKindMultinameL
      variant :MultinameLA, :nested, :class => ABC::MultinameKindMultinameL
      variant :GenericName, :nested, :class => ABC::MultinameKindGenericName
    end

    def method_missing(method, *args, &block)
      data.send(method, *args, &block)
    end

    def to_s
      data.to_s
    end

    def to_astlet(*args)
      node = data.to_astlet(*args)
      node.metadata[:origin] = self
      node
    end
  end
end

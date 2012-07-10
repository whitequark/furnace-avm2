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
      # Fully qualified names required by 1.9.1 compat.
      variant :QName,       :nested, :class => Furnace::AVM2::ABC::MultinameKindQName
      variant :QNameA,      :nested, :class => Furnace::AVM2::ABC::MultinameKindQName
      variant :RTQName,     :nested, :class => Furnace::AVM2::ABC::MultinameKindRTQName
      variant :RTQNameA,    :nested, :class => Furnace::AVM2::ABC::MultinameKindRTQName
      variant :RTQNameL,    :nested, :class => Furnace::AVM2::ABC::MultinameKindRTQNameL
      variant :RTQNameLA,   :nested, :class => Furnace::AVM2::ABC::MultinameKindRTQNameL
      variant :Multiname,   :nested, :class => Furnace::AVM2::ABC::MultinameKindMultiname
      variant :MultinameA,  :nested, :class => Furnace::AVM2::ABC::MultinameKindMultiname
      variant :MultinameL,  :nested, :class => Furnace::AVM2::ABC::MultinameKindMultinameL
      variant :MultinameLA, :nested, :class => Furnace::AVM2::ABC::MultinameKindMultinameL
      variant :GenericName, :nested, :class => Furnace::AVM2::ABC::MultinameKindGenericName
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

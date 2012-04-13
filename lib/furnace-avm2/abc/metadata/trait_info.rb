module Furnace::AVM2::ABC
  class TraitInfo < Record
    XlatTable = {
      :Slot     => 0,
      :Method   => 1,
      :Getter   => 2,
      :Setter   => 3,
      :Class    => 4,
      :Function => 5,
      :Const    => 6
    }

    TRAIT_FINAL    = 0x01
    TRAIT_OVERRIDE = 0x02
    TRAIT_METADATA = 0x04

    attr_accessor :kind_raw

    def read_attributes(io, options)
      byte = io.read(1).unpack("C").at(0)

      value     = byte >> 4
      @kind_raw = byte & 0xF

      value
    end

    def write_attributes(io, value, options)
      byte = (value << 4) | (@kind_raw & 0xf)

      io.write([ byte ].pack("C"))
    end

    const_ref  :name, :multiname

    attributes :attributes
    flag       :final,      :attributes, TRAIT_FINAL
    flag       :override,   :attributes, TRAIT_OVERRIDE
    flag       :metadata,   :attributes, TRAIT_METADATA

    xlat_field :kind

    choice     :data, :selection => :kind do
      variant :Slot,     :nested, :class => TraitSlot
      variant :Method,   :nested, :class => TraitMethod
      variant :Getter,   :nested, :class => TraitMethod
      variant :Setter,   :nested, :class => TraitMethod
      variant :Class,    :nested, :class => TraitClass
      variant :Function, :nested, :class => TraitFunction
      variant :Const,    :nested, :class => TraitSlot
    end

    root_array_of :metadata, :metadata, :plural => :metadata, :if => :metadata?

    def method_missing(method, *args, &block)
      data.send(method, *args, &block)
    end

    def to_astlet
      data.to_astlet(self)
    end
  end
end

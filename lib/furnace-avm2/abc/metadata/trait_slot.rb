module Furnace::AVM2::ABC
  class TraitSlot < Record
    XlatTable = {
      :Int                => 0x03,
      :UInt               => 0x04,
      :Double             => 0x06,
      :Utf8               => 0x01,
      :True               => 0x0B,
      :False              => 0x0A,
      :Null               => 0x0C,
      :Undefined          => 0x00,
      :Namespace          => 0x08,
      :PackageNamespace   => 0x16,
      :PackageInternalNs  => 0x17,
      :ProtectedNamespace => 0x18,
      :ExplicitNamespace  => 0x19,
      :StaticProtectedNs  => 0x1A,
      :PrivateNs          => 0x05,
    }

    vuint30    :idx
    const_ref  :type,   :multiname

    vuint30    :value_idx

    uint8      :value_kind_raw, :if => lambda { value_idx != 0 }
    xlat_field :value_kind

    def to_astlet(trait)
      AST::Node.new(:slot, [ (trait.name ? trait.name.to_astlet : nil), (type ? type.to_astlet : nil), value, idx ])
    end

    def value
      if value_idx > 0
        case value_kind
        when :Int
          AST::Node.new(:integer, [ root.constant_pool.ints[value_idx - 1] ])
        when :UInt
          AST::Node.new(:integer, [ root.constant_pool.uints[value_idx - 1] ])
        when :Double
          AST::Node.new(:double, [ root.constant_pool.doubles[value_idx - 1] ])
        when :Utf8
          AST::Node.new(:string, [ root.constant_pool.strings[value_idx - 1] ])
        when :True
          AST::Node.new(:true)
        when :False
          AST::Node.new(:false)
        when :Null
          AST::Node.new(:null)
        when :Undefined
          AST::Node.new(:undefined)
        else
          raise "unknown value kind #{value_kind}"
        end
      else
        nil
      end
    end

    def ruby_value
      astlet_value = self.value
      if astlet_value
        if astlet_value.children.count > 0
          astlet_value.children.first
        else
          astlet_value.name
        end
      end
    end
  end
end

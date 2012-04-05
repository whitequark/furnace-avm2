module Furnace::AVM2::ABC
  module RecordWithValue
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
      if value_idx > 0
        case value_kind
        when :Int
          root.constant_pool.ints[value_idx - 1]
        when :UInt
          root.constant_pool.uints[value_idx - 1]
        when :Double
          root.constant_pool.doubles[value_idx - 1]
        when :Utf8
          root.constant_pool.strings[value_idx - 1]
        when :True
          true
        when :False
          false
        when :Null
          nil
        when :Namespace
          :"%%Namespace"
        else
          raise "unknown value kind #{value_kind}"
        end
      else
        nil
      end
    end

    def printable_value
      if value_idx > 0
        case value_kind
        when :Null
          "null"
        when :Undefined
          "undefined"
        when :Int, :UInt, :Double, :Utf8, :True, :False
          ruby_value.inspect
        end
      else
        nil
      end
    end
  end
end
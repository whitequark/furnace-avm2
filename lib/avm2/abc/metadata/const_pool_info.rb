module AVM2::ABC
  class ConstPoolInfo < NestedRecord
    def self.cpool_array_of(name, type)
      field_size, field_array = :"#{name}_count", :"#{name}s"

      vuint30        field_size, :value => lambda { send(field_array).count == 0 ? 0 : send(field_array).count + 1 }
      constant_array field_array, :type => type, :initial_length => lambda { send(field_size) - 1 }
    end

    cpool_array_of :int,       :vint32
    cpool_array_of :uint,      :vuint32
    cpool_array_of :double,    :double
    cpool_array_of :string,    :vstring
    cpool_array_of :namespace, :namespace_info
    cpool_array_of :ns_set,    :ns_set_info
    cpool_array_of :multiname, :multiname_info
  end
end
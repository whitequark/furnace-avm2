module AVM2::ABC
  class ConstPoolInfo < Record
    def self.cpool_array_of(name, type, options={})
      field_size, field_array = :"#{name}_count", :"#{name}s"

      vuint30 field_size, :value => lambda { send(field_array).count == 0 ? 0 : send(field_array).count + 1 }
      array   field_array, :type => type, :initial_length => lambda { send(field_size) - 1 }, :options => options
    end

    cpool_array_of :int,       :vint32
    cpool_array_of :uint,      :vuint32
    cpool_array_of :double,    :double
    cpool_array_of :string,    :vstring
    cpool_array_of :namespace, :nested, :class => NamespaceInfo
    cpool_array_of :ns_set,    :nested, :class => NsSetInfo
    cpool_array_of :multiname, :nested, :class => MultinameInfo
  end
end
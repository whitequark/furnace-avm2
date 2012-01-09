module AVM2::ABC
  class Record < BinData::Record
    endian :little

    def self.abc_array_of(name, type, options={})
      field_size, field_array = :"#{name}_count", options.delete(:plural) || :"#{name}s"

      vuint30      field_size,  { :value => lambda { send(field_array).count } }.merge(options)
      nested_array field_array, { :type => type, :initial_length => lambda { send(field_size) } }.merge(options)
    end

    def self.const_ref(name, type, options={})
      vuint30 :"#{name}_idx"
    end

    def self.xlat_direct
      @xlat_direct  ||= const_get(:XlatTable).invert
    end

    def self.xlat_inverse
      @xlat_inverse ||= const_get(:XlatTable)
    end

    def self.constant_table(hash)
      hash.each do |constant, value|
        const_set constant, value
      end
    end
  end
end
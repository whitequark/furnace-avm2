module AVM2::ABC
  class Record < BinData::Record
    endian :little

    def self.abc_array_of(name, type, options={})
      field_size, field_array = :"#{name}_count", options.delete(:plural) || :"#{name}s"

      vuint30      field_size,  { :value => lambda { send(field_array).count } }.merge(options)
      nested_array field_array, { :type => type, :initial_length => lambda { send(field_size) } }.merge(options)
    end

    def self.constant_table(hash)
      hash.each do |constant, value|
        const_set constant, value
      end
    end
  end
end
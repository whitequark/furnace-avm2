module AVM2::ABC
  class Record < AVM2::Binary::Record
    def self.abc_array_of(name, type, options={})
      field_size, field_array = :"#{name}_count", options.delete(:plural) || :"#{name}s"
      klass = options.delete(:class)

      vuint30  field_size,  { :value   => lambda { send(field_array).count } }.merge(options)
      array    field_array, { :type    => type, :initial_length => field_size,
                              :options => { :class => klass } }.merge(options)
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

    def self.xlat_field(name)
      define_method(:"#{name}") do
        value = instance_variable_get :"@#{name}_raw"

        unless self.class.xlat_direct.has_key? value
          raise ArgumentError, "Unknown xlat value #{value} for #{self.class}"
        end

        self.class.xlat_direct[value]
      end

      define_method(:"#{name}=") do |new_value|
        unless self.class.xlat_inverse.has_key? new_value
          raise ArgumentError, "Unknown xlat identifier #{new_value} for #{self.class}"
        end

        instance_variable_set :"@#{name}_raw", self.class.xlat_inverse[new_value]
      end
    end
  end
end
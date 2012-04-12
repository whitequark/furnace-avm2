module Furnace::AVM2::ABC
  class Record < Furnace::AVM2::Binary::Record
    def self.abc_array_of(name, type, options={})
      field_size, field_array = :"#{name}_count", options.delete(:plural) || :"#{name}s"
      klass = options.delete(:class)

      vuint30  field_size,  { :value   => lambda { send(field_array).count } }.merge(options)
      array    field_array, { :type    => type, :initial_length => field_size,
                              :options => { :class => klass } }.merge(options)
    end

    # Pools

    def self.pool_ref(pool, name, type=name, options={})
      field, array = :"#{name}_idx", options.delete(:plural) || :"#{type}s"

      vuint30 field, options

      if pool == :root
        define_method(name) do
          root.send(array)[send(field)]
        end
      elsif pool == :const
        define_method(name) do
          index = send(field)
          if index == 0
            nil
          else
            root.constant_pool.send(array)[index - 1]
          end
        end

        define_method(:"#{name}=") do |value|
          pool = root.constant_pool.send(array)
          if value.nil?
            send(:"#{field}=", 0)
          elsif index = pool.index(value)
            send(:"#{field}=", index + 1)
          else
            raise "cpool setter: no such object in cpool"
          end
        end
      end
    end

    def self.pool_array(pool, name, type, options={})
      field, type_plural = :"#{name}_raw", options.delete(:plural) || :"#{type}s"

      array field, { :type => :vuint30 }.merge(options)

      if pool == :root
        define_method(name) do
          send(field).map do |element|
            root.send(type_plural)[element]
          end
        end
      elsif pool == :const
        define_method(name) do
          send(field).map do |element|
            if element == 0
              nil
            else
              root.constant_pool.send(type_plural)[element - 1]
            end
          end
        end
      end
    end

    def self.pool_array_of(pool, name, type, options={})
      field_size, field_array = :"#{name}_count", options.delete(:plural) || :"#{name}s"

      vuint30          field_size,        { :value => lambda { send(field_array).count } }.merge(options)
      pool_array pool, field_array, type, { :initial_length => field_size }.merge(options)
    end

    # Pool references

    [:root, :const].each do |pool|
      [:ref, :array, :array_of].each do |method|
        define_singleton_method(:"#{pool}_#{method}") do |*args|
          send(:"pool_#{method}", pool, *args)
        end
      end
    end

    # Xlat

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

    # Flags

    def self.flag(name, field, constant)
      define_method(:"#{name}?") do
        instance_variable_get(:"@#{field}") & constant != 0
      end

      define_method(:"#{name}=") do |is_set|
        flags = instance_variable_get(:"@#{field}")

        if is_set
          instance_variable_set(:"@#{field}", flags | constant)
        else
          instance_variable_set(:"@#{field}", flags & ~constant)
        end
      end
    end

    # Subsetting

    def self.subset(name, array, selector)
      define_method(:"#{name}") do
        send(array).select &selector
      end
    end
  end
end
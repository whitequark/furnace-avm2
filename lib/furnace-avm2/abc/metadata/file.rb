module Furnace::AVM2::ABC
  class File < Record
    uint16          :minor_version
    uint16          :major_version

    nested          :constant_pool, :class => ConstPoolInfo

    abc_array_of    :method,        :nested, :class => MethodInfo

    abc_array_of    :metadata,      :nested, :class => MetadataInfo

    vuint30         :klass_count,   :value => lambda { instances.count }
    array           :instances,     :type => :nested, :initial_length => :klass_count,
                                    :options => { :class => InstanceInfo }
    array           :klasses,       :type => :nested, :initial_length => :klass_count,
                                    :options => { :class => KlassInfo }
    subset          :interfaces,    :instances, :interface?

    abc_array_of    :script,        :nested, :class => ScriptInfo

    abc_array_of    :method_body,   :nested, :class => MethodBodyInfo, :plural => :method_bodies

    def root
      self
    end

    def method_body_at(index)
      @method_body_indexes[index]
    end

    def fix_names!
      @name_set = Set.new(constant_pool.strings)

      constant_pool.namespaces.each do |ns|
        fix_name!(ns.name_idx, ns: true)
      end

      constant_pool.multinames.each do |multiname|
        if [:QName, :QNameA,
            :Multiname, :MultinameA,
            :RTQName, :RTQMameA].include? multiname.kind
          fix_name!(multiname.data.name_idx)
        end
      end
    end

    def fix_name!(name_idx, options={})
      old_name = constant_pool.strings[name_idx - 1]
      return if ["", "*"].include? old_name

      fixed_name = sanitize_name(old_name, options)

      if old_name != fixed_name
        index = 0
        indexed_name = fixed_name
        while @name_set.include? indexed_name
          indexed_name = "#{fixed_name}_i#{index}"
          index += 1
        end

        @name_set.add indexed_name

        constant_pool.strings[name_idx - 1] = indexed_name
      end
    end

    def sanitize_name(name, options={})
      if options[:ns]
        return name if name.start_with? "http://"

        name.split('.').map do |part|
          part.gsub(/^[^a-zA-Z_$]+/, '').
            gsub(/[^a-zA-Z_$0-9:]+/, '')
        end.reject do |part|
          part.empty?
        end.join('.')
      else
        name.gsub(/^[^a-zA-Z_$]+/, '').
          gsub(/[^a-zA-Z_$0-9:]+/, '')
      end
    end

    protected

    def after_read(io)
      @method_body_indexes = {}
      method_bodies.each do |body|
        @method_body_indexes[body.method_idx] = body
      end
    end
  end
end
module AVM2::ABC
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

    abc_array_of    :script,        :nested, :class => ScriptInfo

    abc_array_of    :method_body,   :nested, :class => MethodBodyInfo, :plural => :method_bodies

    def root
      self
    end
  end
end
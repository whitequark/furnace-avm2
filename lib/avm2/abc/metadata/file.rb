module AVM2::ABC
  class File < Record
    uint16          :minor_version
    uint16          :major_version

    const_pool_info :constant_pool

    abc_array_of    :klass_method, :method_info

    abc_array_of    :metadata, :metadata_info

    vuint30         :klass_count,                        :value => lambda { instances.count }
    array           :instances, :type => :instance_info, :initial_length => :klass_count
    array           :klasses, :type => :klass_info,      :initial_length => :klass_count

    abc_array_of    :script, :script_info

    abc_array_of    :method_body, :method_body_info,     :plural => :method_bodies
  end
end
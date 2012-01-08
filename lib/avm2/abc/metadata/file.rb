module AVM2::ABC
  class File < Record
    uint16           :minor_version
    uint16           :major_version

    const_pool_info  :constant_pool

    vuint30          :klass_method_count,                   :value => lambda { klass_methods.count }
    array            :klass_methods, :type => :method_info, :initial_length => :klass_method_count

    vuint30          :metadata_count,                       :value => lambda { metadata.count }
    array            :metadata, :type => :metadata_info,    :initial_length => :metadata_count

    vuint30          :klass_count,                          :value => lambda { instances.count }
    array            :instances, :type => :instance_info,   :initial_length => :klass_count
    array            :klasses, :type => :klass_info,        :initial_length => :klass_count

    vuint30          :script_count,                         :value => lambda { scripts.count }
    array            :scripts, :type => :script_info,       :initial_length => :script_count

#     uint30           :method_body_count, :value => lambda { method_bodies.count }
#     method_body_info :method_bodies,     :initial_length => :method_body_count
  end
end
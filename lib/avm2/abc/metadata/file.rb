module AVM2::ABC
  class File < Record
    uint16           :minor_version
    uint16           :major_version

    const_pool_info  :constant_pool
#
#     uint30           :method_count,      :value => lambda { methods.count }
#     method_info      :methods,           :initial_length => :method_count
#
#     uint30           :metadata_count,    :value => lambda { metadata.count }
#     metadata_info    :metadata,          :initial_length => :metadata_count
#
#     uint30           :klass_count,       :value => lambda { klasses.count }
#     instance_info    :instances,         :initial_length => :klass_count
#     klass_info       :klasses,           :initial_length => :klass_count
#
#     uint30           :script_count,      :value => lambda { scripts.count }
#     script_info      :scripts,           :initial_length => :script_count
#
#     uint30           :method_body_count, :value => lambda { method_bodies.count }
#     method_body_info :method_bodies,     :initial_length => :method_body_count
  end
end
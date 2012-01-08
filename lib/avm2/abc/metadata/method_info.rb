module AVM2::ABC
  class MethodInfo < Record
    NEED_ARGUMENTS  = 0x01
    NEED_ACTIVATION = 0x02
    NEED_REST       = 0x04
    HAS_OPTIONAL    = 0x08
    SET_DXNS        = 0x40
    HAS_PARAM_NAMES = 0x80

    vuint30     :param_count, :value => lambda { param_types.count }
    vuint30     :return_type
    array       :param_types, :type => :vuint30, :initial_length => :param_count
    vuint30     :name

    uint8       :flags
    option_info :options, :only_if => lambda { flags & HAS_OPTIONAL != 0 }
    array       :param_names, :type => :vuint30, :initial_length => :param_count, :only_if => lambda { flags & HAS_PARAM_NAMES != 0 }
  end
end

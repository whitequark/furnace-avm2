module Furnace::AVM2::ABC
  class MethodInfo < Record
    NEED_ARGUMENTS  = 0x01
    NEED_ACTIVATION = 0x02
    NEED_REST       = 0x04
    HAS_OPTIONAL    = 0x08
    SET_DXNS        = 0x40
    HAS_PARAM_NAMES = 0x80

    vuint30       :param_count, :value => lambda { param_types.count }

    const_ref     :return_type, :multiname
    const_array   :param_types, :multiname, :initial_length => :param_count

    const_ref     :name, :string

    uint8         :flags
    flag          :needs_arguments,  :flags, NEED_ARGUMENTS
    flag          :needs_activation, :flags, NEED_ACTIVATION
    flag          :needs_rest,       :flags, NEED_REST
    flag          :has_defaults,     :flags, HAS_OPTIONAL
    flag          :set_dxns,         :flags, SET_DXNS
    flag          :has_param_names,  :flags, HAS_PARAM_NAMES

    abc_array_of  :default, :nested, :class => DefaultValue, :if => :has_defaults?

    const_array   :param_names, :string, :initial_length => :param_count, :if => :has_param_names?

    def to_astlet(index, name=nil)
      root = AST::Node.new(:method)
      root.metadata = { method: self, label: index }

      root.children << name || self.name

      if return_type
        root.children << return_type.to_astlet
      else
        root.children << nil
      end

      if has_param_names?
        names = param_names
      else
        names = param_count.times.map { |n| "a#{n}" }
      end

      root.children << names.each_with_index.map do |name, index|
        if param_types[index]
          [ name, param_types[index].to_astlet ]
        else
          [ name, nil ]
        end
      end

      root.normalize_hierarchy!
    end

    def collect_ns(options)
      param_types.compact.each { |type| type.collect_ns(options) }
      return_type.collect_ns(options) if return_type
    end
  end
end

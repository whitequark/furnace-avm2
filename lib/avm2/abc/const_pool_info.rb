module AVM2::ABC
  class ConstPoolInfo < Record
    vuint30 :int_count,                      :value => lambda { ints.count + 1 }
    array   :ints, :type => :vint32,         :initial_length => lambda { int_count - 1 }

    vuint30 :uint_count,                     :value => lambda { uints.count + 1 }
    array   :uints, :type => :vuint32,       :initial_length => lambda { uint_count - 1 }

    vuint30 :double_count,                   :value => lambda { doubles.count + 1 }
    array   :doubles, :type => :double,      :initial_length => lambda { double_count - 1 }

    vuint30 :string_count,                   :values => lambda { strings.count + 1 }
    array   :strings, :type => :string_info, :initial_length => lambda { string_count + 1 }
  end
end
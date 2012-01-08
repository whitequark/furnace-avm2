module AVM2::ABC
  class ConstPoolInfo < Record
    uint30 :int_count,      :value => lambda { ints.count }
    vint32 :ints,           :initial_length => :method_count
  end
end
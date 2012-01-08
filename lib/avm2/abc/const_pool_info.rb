module AVM2::ABC
  class ConstPoolInfo < Record
    vuint30 :int_count,              :value => lambda { ints.count }
    array   :ints, :type => :vint32, :initial_length => :int_count
  end
end
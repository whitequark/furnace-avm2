module AVM2::ABC
  class OptionInfo < Record
    vuint30 :option_count,                     :value => lambda { options.count }
    array   :options, :type => :option_detail, :initial_length => :option_count
  end
end

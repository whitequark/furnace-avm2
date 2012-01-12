module AVM2::ABC
  class OptionInfo < Record
    abc_array_of :option, :nested, :class => OptionDetail
  end
end

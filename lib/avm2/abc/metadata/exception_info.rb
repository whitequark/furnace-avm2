module AVM2::ABC
  class ExceptionInfo < NestedRecord
    vuint30 :from
    vuint30 :to
    vuint30 :target
    vuint30 :exc_type
    vuint30 :name
  end
end

module AVM2::ABC
  class ExceptionInfo < Record
    vuint30   :from
    vuint30   :to
    vuint30   :target
    const_ref :exc_type, :string
    const_ref :var_name, :string
  end
end

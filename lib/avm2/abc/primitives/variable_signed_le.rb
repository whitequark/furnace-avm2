module AVM2::ABC
  class VariableSignedLE < VariableUnsignedLE
    def value_to_binary_string(value)
      super(value, true)
    end

    def read_and_return_value(io)
      super(io, true)
    end
  end
end
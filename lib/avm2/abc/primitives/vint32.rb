module AVM2::ABC
  class Vint32 < VariableIntegerLE
    def self.signed?
      true
    end
  end
end
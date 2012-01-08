module AVM2::ABC
  class Vuint32 < VariableIntegerLE
    def self.signed?
      false
    end
  end
end
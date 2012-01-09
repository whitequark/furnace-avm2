module AVM2::ABC
  class Vstring < BinData::Primitive
    vuint30 :data_size, :value => lambda { data.length }
    string  :data,      :read_length => :data_size

    def get
      self.data
    end

    def set(value)
      self.data = value
    end
  end
end
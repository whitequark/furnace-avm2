module AVM2::ABC
  class StringInfo < BinData::Record
    vuint30 :str_length, :value => lambda { data.length }
    string  :data,       :read_length => :str_length
  end
end
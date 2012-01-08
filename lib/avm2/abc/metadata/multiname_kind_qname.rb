module AVM2::ABC
  class MultinameKindQname < BinData::Record
    vuint30 :name
    vuint30 :ns
  end
end

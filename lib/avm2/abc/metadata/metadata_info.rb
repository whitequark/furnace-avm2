module AVM2::ABC
  class MetadataInfo < NestedRecord
    vuint30      :name

    vuint30      :item_count,  :value => lambda { item_keys.count }
    array        :item_keys,   :type => :vuint30, :initial_length => :item_count
    array        :item_values, :type => :vuint30, :initial_length => :item_count
  end
end

module AVM2::ABC
  class MetadataInfo < Record
    vuint30   :name
    vuint30   :item_count, :value => lambda { items.count }
    array     :items, :type => :item_info, :initial_length => :item_count
  end
end

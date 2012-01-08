module AVM2::ABC
  class MetadataInfo < Record
    vuint30      :name

    abc_array_of :item, :item_info
  end
end

module Furnace::AVM2::ABC
  class MetadataInfo < Record
    const_ref   :name, :string

    vuint30     :item_count,  :value => lambda { item_keys.count }
    const_array :item_keys,   :string, :initial_length => :item_count
    const_array :item_values, :string, :initial_length => :item_count

    def to_hash
      hash = {}

      item_count.times do |n|
        hash[item_keys[n]] = item_values[n]
      end

      hash
    end
  end
end

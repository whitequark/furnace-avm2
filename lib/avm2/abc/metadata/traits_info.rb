module AVM2::ABC
  class TraitsInfo < Record
    Kinds = {
      :Slot     => 0,
      :Method   => 1,
      :Getter   => 2,
      :Setter   => 3,
      :Class    => 4,
      :Function => 5,
      :Const    => 6
    }

    Final    = 0x01
    Override = 0x02
    Metadata = 0x04

    vuint30  :name
    bit4     :attributes
    bit4     :kind, :check_value => lambda { Kinds.values.include? value }

    choice   :data, :selection => :kind do
      trait_slot     Kinds[:Slot]
      trait_method   Kinds[:Method]
      trait_method   Kinds[:Getter]
      trait_method   Kinds[:Setter]
      trait_class    Kinds[:Class]
      trait_function Kinds[:Function]
      trait_slot     Kinds[:Const]
    end

    vuint30  :metadata_count, :value => lambda { metadata.count() }, :onlyif => lambda { attributes & Metadata != 0}
    array    :metadata, :type => :vuint30, :initial_length => :metadata_count, :onlyif => lambda { attributes & Metadata != 0 }
  end
end

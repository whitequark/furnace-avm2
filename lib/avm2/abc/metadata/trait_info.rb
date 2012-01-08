module AVM2::ABC
  class TraitInfo < Record
    Kinds = {
      :Slot     => 0,
      :Method   => 1,
      :Getter   => 2,
      :Setter   => 3,
      :Class    => 4,
      :Function => 5,
      :Const    => 6
    }

    constant_table Kinds

    Final    = 0x01
    Override = 0x02
    Metadata = 0x04

    vuint30  :name
    bit4     :attributes
    bit4     :kind, :check_value => lambda { Kinds.values.include? value }

    choice   :data, :selection => :kind do
      trait_slot     Slot
      trait_method   Method
      trait_method   Getter
      trait_method   Setter
      trait_class    Class
      trait_function Function
      trait_slot     Const
    end

    abc_array_of :metadata, :vuint30, :plural => :metadata, :onlyif => lambda { attributes & Metadata != 0 }
  end
end

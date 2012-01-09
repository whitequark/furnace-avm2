module AVM2::ABC
  class TraitInfo < NestedRecord
    XlatTable = {
      :Slot     => 0,
      :Method   => 1,
      :Getter   => 2,
      :Setter   => 3,
      :Class    => 4,
      :Function => 5,
      :Const    => 6
    }

    FINAL    = 0x01
    OVERRIDE = 0x02
    METADATA = 0x04

    vuint30   :name

    bit4      :attributes
    xlat_bit4 :kind, :type => :bit4

    choice    :data, :selection => :kind do
      trait_slot     XlatTable[:Slot]
      trait_method   XlatTable[:Method]
      trait_method   XlatTable[:Getter]
      trait_method   XlatTable[:Setter]
      trait_class    XlatTable[:Class]
      trait_function XlatTable[:Function]
      trait_slot     XlatTable[:Const]
    end

    abc_array_of :metadata, :vuint30, :plural => :metadata, :onlyif => lambda { attributes & METADATA != 0 }
  end
end

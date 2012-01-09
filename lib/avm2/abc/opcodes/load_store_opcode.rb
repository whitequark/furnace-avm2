module AVM2::ABC
  class LoadStoreOpcode < Opcode
    define_property :direction
    define_property :index,    :callable => true
  end
end
module Furnace::AVM2::ABC
  class LoadStoreOpcode < Opcode
    define_property :direction
    define_property :index,    :callable => true

    def parameters
      [ index ]
    end

    def ast_type
      if direction == :load
        :get_local
      elsif direction == :store
        :set_local
      end
    end
  end
end
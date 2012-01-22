module AVM2::ABC
  class PushLiteralOpcode < Opcode
    consume 0
    produce 1

    def ast_type
      type
    end

    def parameters
      if respond_to? :body
        [ body.value ]
      else
        [ ]
      end
    end
  end
end
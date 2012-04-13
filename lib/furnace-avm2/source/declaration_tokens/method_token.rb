require_relative 'callee_token'

module Furnace::AVM2::Tokens
  class MethodToken < CalleeToken
    def initialize(origin, options={})
      super(origin, [
        MetadataToken.new(origin, options),
        MethodSpecifiersToken.new(origin, options),
        FunctionNameToken.new(origin, [
          MultinameToken.new(origin, origin.name, options.merge(omit_ns: true))
        ], options),
      ], origin.data.method, origin.body,
         options.merge({ index: origin.data.method_idx }))
    end
  end
end
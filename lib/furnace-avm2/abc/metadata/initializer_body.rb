module Furnace::AVM2::ABC
  module InitializerBody
    def initializer_body
      root.method_bodies.find { |body| body.method_idx == initializer_idx }
    end
  end
end


module Furnace::AVM2::Transform
  AST = Furnace::AST
end

require_relative "transform/ast_build"
require_relative "transform/ast_normalize"
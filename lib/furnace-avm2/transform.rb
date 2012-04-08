module Furnace::AVM2::Transform
  AST = Furnace::AST
  CFG = Furnace::CFG
end

require_relative "transform/ast_build"
require_relative "transform/ast_normalize"
require_relative "transform/cfg_build"
require_relative "transform/cfg_reduce"
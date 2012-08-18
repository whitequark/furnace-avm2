module Furnace::AVM2::Transform
  AST = Furnace::AST
  CFG = Furnace::CFG
end

require_relative "transform/phi_node_reduction"

require_relative "transform/cfg_build"
require_relative "transform/refine_local_variable_barriers"
require_relative "transform/ssa_transform"
require_relative "transform/ssa_optimize"
require_relative "transform/liveness_analysis"
require_relative "transform/dataflow_invariant_code_motion"
require_relative "transform/partial_evaluation"
require_relative "transform/fold_ternary_operators"
require_relative "transform/fold_boolean_shortcuts"
require_relative "transform/fold_passthrough_assignments"
require_relative "transform/fold_increment_decrement"
require_relative "transform/update_exception_variables"
require_relative "transform/cfg_reduce"
require_relative "transform/nf_normalize"

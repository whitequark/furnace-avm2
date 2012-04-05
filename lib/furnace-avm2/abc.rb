module Furnace::AVM2::ABC
  AST  = Furnace::AST
  CFG  = Furnace::CFG
end

require_relative "binary/choice_definition"
require_relative "binary/record"

require_relative "abc/primitives/record"
require_relative "abc/primitives/opcode_sequence"

require_relative "abc/opcodes/opcode"
require_relative "abc/opcodes/contextual_opcode"

require_relative "abc/opcodes/load_store_opcode"
require_relative "abc/opcodes/arithmetic_opcode"
require_relative "abc/opcodes/bitwise_opcode"
require_relative "abc/opcodes/type_conversion_opcode"
require_relative "abc/opcodes/push_literal_opcode"
require_relative "abc/opcodes/control_transfer_opcode"
require_relative "abc/opcodes/function_invocation_opcode"
require_relative "abc/opcodes/function_return_opcode"
require_relative "abc/opcodes/exception_opcode"

require_relative "abc/opcodes/property_opcode"

Dir[File.join(File.dirname(__FILE__), "abc", "opcodes", "*", "*.rb")].each do |file|
  require file
end

Furnace::AVM2::ABC::Opcode::MAP.freeze

require_relative "abc/metadata/namespace_info"
require_relative "abc/metadata/ns_set_info"
require_relative "abc/metadata/multiname_kind_multiname"
require_relative "abc/metadata/multiname_kind_multinamel"
require_relative "abc/metadata/multiname_kind_qname"
require_relative "abc/metadata/multiname_kind_rtqname"
require_relative "abc/metadata/multiname_kind_rtqnamel"
require_relative "abc/metadata/multiname_kind_genericname"
require_relative "abc/metadata/multiname_info"
require_relative "abc/metadata/const_pool_info"

require_relative "abc/metadata/record_with_value"

require_relative "abc/metadata/trait_slot"
require_relative "abc/metadata/trait_method"
require_relative "abc/metadata/trait_class"
require_relative "abc/metadata/trait_function"
require_relative "abc/metadata/trait_info"

require_relative "abc/metadata/default_value"
require_relative "abc/metadata/method_info"

require_relative "abc/metadata/metadata_info"

require_relative "abc/metadata/record_with_traits"

require_relative "abc/metadata/instance_info"
require_relative "abc/metadata/klass_info"

require_relative "abc/metadata/script_info"

require_relative "abc/metadata/exception_info"
require_relative "abc/metadata/method_body_info"

require_relative "abc/metadata/file"

Furnace::AVM2::Binary::Record.codegen_each

require_relative "abc/tokens/token_with_traits"

Dir[File.join(File.dirname(__FILE__), "abc", "tokens", "*.rb")].each do |file|
  require file
end
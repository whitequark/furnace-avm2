module AVM2::ABC
  AST = Furnace::AST
  CFG = Furnace::CFG
end

require "avm2/binary/choice_definition"
require "avm2/binary/record"

require "avm2/abc/primitives/record"
require "avm2/abc/primitives/opcode_sequence"

require "avm2/abc/opcodes/opcode"
require "avm2/abc/opcodes/contextual_opcode"

require "avm2/abc/opcodes/load_store_opcode"
require "avm2/abc/opcodes/arithmetic_opcode"
require "avm2/abc/opcodes/bitwise_opcode"
require "avm2/abc/opcodes/type_conversion_opcode"
require "avm2/abc/opcodes/push_literal_opcode"
require "avm2/abc/opcodes/control_transfer_opcode"
require "avm2/abc/opcodes/function_invocation_opcode"
require "avm2/abc/opcodes/function_return_opcode"
require "avm2/abc/opcodes/exception_opcode"

require "avm2/abc/opcodes/property_opcode"

Dir[File.join(File.dirname(__FILE__), "abc", "opcodes", "*", "*.rb")].each do |file|
  require file
end

AVM2::ABC::Opcode::MAP.freeze

require "avm2/abc/metadata/namespace_info"
require "avm2/abc/metadata/ns_set_info"
require "avm2/abc/metadata/multiname_kind_multiname"
require "avm2/abc/metadata/multiname_kind_multinamel"
require "avm2/abc/metadata/multiname_kind_qname"
require "avm2/abc/metadata/multiname_kind_rtqname"
require "avm2/abc/metadata/multiname_kind_rtqnamel"
require "avm2/abc/metadata/multiname_kind_genericname"
require "avm2/abc/metadata/multiname_info"
require "avm2/abc/metadata/const_pool_info"

require "avm2/abc/metadata/option_detail"
require "avm2/abc/metadata/option_info"
require "avm2/abc/metadata/method_info"

require "avm2/abc/metadata/metadata_info"

require "avm2/abc/metadata/trait_slot"
require "avm2/abc/metadata/trait_method"
require "avm2/abc/metadata/trait_class"
require "avm2/abc/metadata/trait_function"
require "avm2/abc/metadata/trait_info"
require "avm2/abc/metadata/instance_info"
require "avm2/abc/metadata/klass_info"

require "avm2/abc/metadata/script_info"

require "avm2/abc/metadata/exception_info"
require "avm2/abc/metadata/method_body_info"

require "avm2/abc/metadata/file"

AVM2::Binary::Record.codegen_each

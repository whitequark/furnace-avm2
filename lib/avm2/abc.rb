module AVM2
  module ABC
    class Record < BinData::Record
      endian :little
    end
  end
end

require "avm2/abc/primitives/variable_integer_le"
require "avm2/abc/primitives/vuint30"
require "avm2/abc/primitives/vuint32"
require "avm2/abc/primitives/vint32"

require "avm2/abc/metadata/string_info"
require "avm2/abc/metadata/namespace_info"
require "avm2/abc/metadata/ns_set_info"
require "avm2/abc/metadata/multiname_kind_multiname"
require "avm2/abc/metadata/multiname_kind_multinamel"
require "avm2/abc/metadata/multiname_kind_qname"
require "avm2/abc/metadata/multiname_kind_rtqname"
require "avm2/abc/metadata/multiname_kind_rtqnamel"
require "avm2/abc/metadata/multiname_info"
require "avm2/abc/metadata/const_pool_info"

require "avm2/abc/metadata/option_detail"
require "avm2/abc/metadata/option_info"
require "avm2/abc/metadata/method_info"

require "avm2/abc/metadata/item_info"
require "avm2/abc/metadata/metadata_info"

require "avm2/abc/metadata/trait_slot"
require "avm2/abc/metadata/trait_method"
require "avm2/abc/metadata/trait_class"
require "avm2/abc/metadata/trait_function"
require "avm2/abc/metadata/traits_info"
require "avm2/abc/metadata/instance_info"
require "avm2/abc/metadata/klass_info"

require "avm2/abc/metadata/file"

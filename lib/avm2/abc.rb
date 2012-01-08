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

require "avm2/abc/metadata/file"

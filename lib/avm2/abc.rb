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
require "avm2/abc/metadata/const_pool_info"
require "avm2/abc/metadata/file"

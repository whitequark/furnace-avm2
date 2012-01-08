module AVM2
  module ABC
    class Record < BinData::Record
      endian :little
    end
  end
end

require "avm2/abc/variable_unsigned_le"
require "avm2/abc/variable_signed_le"
require "avm2/abc/vuint30"
require "avm2/abc/vuint32"
require "avm2/abc/vint32"

require "avm2/abc/string_info"
require "avm2/abc/const_pool_info"

require "avm2/abc/file"
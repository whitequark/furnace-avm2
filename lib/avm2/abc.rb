module AVM2
  module ABC
    class Record < BinData::Record
      endian :little
    end
  end
end

require "avm2/abc/variable_unsigned_le"
require "avm2/abc/uint30"
require "avm2/abc/uint32"

require "avm2/abc/const_pool_info"

require "avm2/abc/file"
module AS3
  module Opcodes
    class Switch < Opcode
      class Record < BinData::Record
        endian :little

        uint8 :type
        int24 :default_target
        bit30 :case_count,    :value => lambda { case_targets.length - 1 }
        array :case_targets,  :initial_length => lambda { case_count + 1 } do
          int24
        end
      end

      attr_reader :default_target, :case_targets

      def initialize(stream, bytes)
        super(stream)

        @record = Record.read(bytes)
      end

      def prepare!
        @default_target = @stream.opcode_at_offset(offset + @record.default_target)
        @case_targets   = @record.case_targets.map { |off| @stream.opcode_at_offset off }
      end

      def update!
        @record.default_target = @default_target.offset - offset
        @record.case_targets   = @case_targets.map { |target| target.offset - offset }
      end

      def description
        "_as3_lookupswitch ~#{@default_target.serial}(#{@case_targets.count - 1})" +
            "[#{@case_targets.map { |target| "~#{target.serial}" }.join ", "}]"
      end
    end
  end
end
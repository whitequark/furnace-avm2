module AS3
  class Stream
    OPCODE_MAP = {
      %w{jump iflt ifle ifnlt ifnle ifgt ifge ifngt ifnge
         ifeq ifne ifstricteq ifstrictne iftrue iffalse} => Opcodes::Branch,
      #%w{lookupswitch} => Opcodes::Switch,
    }

    attr_reader :opcodes

    def initialize
      @opcodes = nil
    end

    def parse_assembly(stream)
      @opcodes = []

      stream.lines.map(&:strip).each_slice(2) do |(bytes, description)|
        binary = [ bytes[2..-1].gsub(" ", "") ].pack("H*")
        description =~ /^_as3_(\w+)/

        found = false
        OPCODE_MAP.each do |types, klass|
          if types.include? $1
            @opcodes << klass.new(self, binary)
            found = true
            break
          end
        end

        unless found
          @opcodes << Opcodes::Unknown.new(self, binary.bytes.to_a, description)
        end
      end

      @opcodes.each &:prepare!
    end

    def to_assembly
      output = ""

      @opcodes.each &:update!

      @opcodes.each_with_index do |opcode, index|
        output << "//#{opcode.bytes.map { |b| b.to_s(16).rjust(2, "0") }.join(" ")}\n"
        output << "#{index} #{opcode.description}\n"
      end

      output
    end

    def to_binary
      @opcodes.map(&:bytes).flatten.map(&:chr).join
    end

    def build_cfg
      graph = Furnace::CFG::Graph.new

      targets = []

      @opcodes.each do |opcode|
        if opcode.is_a? Opcodes::Branch
          targets << opcode.target
        end
      end

      @opcodes.each_with_index do |opcode, serial|
        if targets.include? opcode
          graph.transfer({ nil => serial })
        end

        graph.expand serial, opcode

        if opcode.is_a? Opcodes::Branch
          if opcode.conditional?
            graph.transfer({ true => opcode.target.serial,
                            false => serial + 1 })
          else
            graph.transfer({ nil => opcode.target.serial })
          end
        end
      end

      graph.transfer({ })

      graph
    end

    def serial_for(opcode)
      @opcodes.each_with_index do |current, index|
        return index if opcode == current
      end

      raise "Cannot locate serial for opcode"
    end

    def offset_for(opcode)
      current_offset = 0

      @opcodes.each_with_index do |current, index|
        if current == opcode
          return current_offset
        else
          current_offset += current.length
        end
      end

      raise "Cannot locate offset for opcode"
    end

    def opcode_at_serial(serial)
      if serial > @opcodes.length
        return @opcodes[serial]
      end

      raise "Stream too short for serial #{serial}"
    end

    def opcode_at_offset(offset)
      current_offset = 0

      @opcodes.each do |current|
        if current_offset == offset
          return current
        elsif current_offset > offset
          raise "Inconsistent opcode stream"
        else
          current_offset += current.length
        end
      end

      raise "Stream too short for offset #{offset}"
    end
  end
end
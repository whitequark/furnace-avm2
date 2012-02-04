module Furnace::AVM2::ABC
  class OpcodeSequence < ::Array
    attr_reader :root, :parent

    def initialize(options={})
      @root, @parent = options[:parent].root, options[:parent]
      @pos_cache    = {}
      @opcode_cache = {}

      @raw_code = nil
    end

    def read(io)
      @raw_code = io.read(@parent.code_length)
    end

    def write(io)
      if @raw_code
        io.write @raw_code
      else
        lookup!

        each do |opcode|
          opcode.write(io)
        end
      end
    end

    def each(&block)
      parse if @raw_code

      super
    end

    # Offsets

    def recache!
      flush!

      pos = 0
      each do |opcode|
        @pos_cache[pos]       = opcode
        @opcode_cache[opcode] = pos

        pos += opcode.byte_length
      end

      lookup!
    end

    def flush!
      @pos_cache    = {}
      @opcode_cache = {}
    end

    def opcode_at(position)
      @pos_cache[position]
    end

    def offset_of(opcode)
      @opcode_cache[opcode]
    end

    def byte_length
      map(&:byte_length).reduce(0, :+)
    end

    # Transformations

    def disassemble
      map(&:disassemble).join("\n")
    end

    def build_cfg
      graph = CFG::Graph.new

      targets = []

      each do |opcode|
        if opcode.is_a? ControlTransferOpcode
          targets << opcode.target
        elsif opcode.is_a? AS3LookupSwitch
          targets << opcode.default_target
          targets += opcode.case_targets
        end
      end

      if exceptions.any?
        exception_node = CFG::Node.new(graph, :exception, [])
        graph.nodes.add exception_node

        exceptions.each do |exception|
          targets << exception.target_offset
        end
      end

      each do |opcode|
        if targets.include? opcode
          graph.transfer({ nil => opcode.offset })
        end

        graph.expand opcode.offset, opcode

        if opcode.is_a? ControlTransferOpcode
          if opcode.conditional
            graph.transfer({ true  => opcode.target.offset,
                             false => opcode.offset + opcode.byte_length })
          else
            graph.transfer({ nil => opcode.target.offset })
          end
        elsif opcode.is_a? AS3LookupSwitch
          map = { nil => opcode.default_target.offset }

          opcode.case_targets.each_with_index do |target, index|
            map[index] = target.offset
          end

          graph.transfer map
        end
      end

      graph.transfer({ })

      exceptions.each do |exception|
        graph.edges.add CFG::Edge.new(graph, nil, :exception, exception.target_offset)
      end

      graph
    end

    def eliminate_dead!
      cfg = build_cfg
      dead_opcodes = []

      cfg.nodes.each do |node|
        if node.label != 0 && node.entering_edges.count == 0
          dead_opcodes.concat node.operations
        end
      end

      dead_opcodes.each do |opcode|
        delete opcode
      end

      recache!

      dead_opcodes.any?
    end

    protected

    def parse
      sub_io = StringIO.new(@raw_code)
      map    = Opcode::MAP

      until sub_io.eof?
        instruction = sub_io.read(1).unpack("C").at(0)

        opcode = map[instruction]
        if opcode.nil?
          raise "Unknown opcode 0x#{instruction.to_s(16)}"
        end

        element = opcode.new(self)

        @pos_cache[sub_io.pos - 1] = element
        @opcode_cache[element]     = sub_io.pos - 1

        element.read(sub_io)

        self << element
      end

      @raw_code = nil

      each do |element|
        element.resolve! if element.respond_to? :resolve!
      end
    end

    def lookup!
      each do |element|
        element.lookup! if element.respond_to? :lookup!
      end

      exceptions.each do |exception|
        exception.lookup!
      end
    end

    def exceptions
      @parent.exceptions
    end
  end
end
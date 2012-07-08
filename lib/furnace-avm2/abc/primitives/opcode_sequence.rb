require 'stringio'

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

    def each
      parse if @raw_code

      super
    end

    def map
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
      parse if @raw_code

      @pos_cache[position]
    end

    def offset_of(opcode)
      parse if @raw_code

      @opcode_cache[opcode]
    end

    def byte_length
      if @raw_code
        @raw_code.length
      else
        map(&:byte_length).reduce(0, :+)
      end
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

      @parent.exceptions.each do |exc|
        targets << exc.target
      end

      pending_label = nil
      pending_queue = []

      cutoff = lambda do |targets|
        node = CFG::Node.new(graph, pending_label, pending_queue, nil, targets)

        if graph.nodes.empty?
          graph.entry = node
        end

        graph.nodes.add node

        pending_label = nil
        pending_queue = []
      end

      each do |opcode|
        if targets.include? opcode
          cutoff.([ opcode.offset ])
        end

        pending_label = opcode.offset if pending_label.nil?
        pending_queue << opcode

        if opcode.is_a?(ControlTransferOpcode)
          if opcode.conditional
            cutoff.([ opcode.target.offset, opcode.offset + opcode.byte_length ])
          else
            cutoff.([ opcode.target.offset ])
          end
        elsif opcode.is_a?(AS3LookupSwitch)
          cutoff.(opcode.parameters.flatten)
        elsif opcode.is_a?(FunctionReturnOpcode) ||
              opcode.is_a?(AS3Throw)
          cutoff.([])
        end
      end

      cutoff.([])

      if exceptions.any?
        exception_node = CFG::Node.new(graph, :exception, [], nil,
            exceptions.map(&:target_offset))
        graph.nodes.add exception_node
      end

      graph
    end

    def eliminate_dead!
      begin
        cfg = build_cfg
      rescue Exception => e
        # Ignore. This will fail at later stages.
        return false
      end

      worklist = Set[cfg.entry]
      @parent.exceptions.each do |exc|
        worklist.add cfg.find_node(exc.target_offset)
      end

      livelist = Set[]
      while worklist.any?
        node = worklist.first
        worklist.delete node

        livelist.add node

        node.targets.each do |target|
          worklist.add target unless livelist.include? target
        end
      end

      cfg.nodes.each do |node|
        unless livelist.include? node
          node.insns.each do |opcode|
            delete opcode
          end
        end
      end

      recache!

      livelist != cfg.nodes
    end

    private

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

      exceptions.each do |exception|
        exception.resolve!
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
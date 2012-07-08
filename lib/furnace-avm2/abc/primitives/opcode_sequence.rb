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
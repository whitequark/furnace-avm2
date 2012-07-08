module Furnace::AVM2::ABC
  class Opcode
    MAP = {}

    # Metamethods

    def self.define_property(name, options={}, &block)
      accessor_name = options[:accessor] || name

      define_singleton_method(name) do |value=nil, &value_block|
        if value_block
          define_method(accessor_name) do
            instance_exec &value_block
          end
        elsif !value.nil?
          define_method(accessor_name) do
            value
          end
        else
          define_method(accessor_name) do
            true
          end
        end

        instance_exec(value, &block) if block
      end
    end

    def self.body(&block)
      @body_defined = true

      klass = Class.new(Record)
      klass.instance_exec &block

      const_set :Body, klass

      attr_accessor :body
    end

    def self.mnemonic
      @mnemonic ||= name.sub("Furnace::AVM2::ABC::AS3", "")
    end

    # Common definitions

    define_property :instruction do |encoding|
      MAP[encoding] = self
    end

    define_property :ast_type

    define_property :consume_context, :accessor => :consumes_context
    define_property :consume,         :accessor => :consumes
    define_property :produce,         :accessor => :produces

    define_property :type

    attr_reader :sequence

    def initialize(sequence)
      @sequence = sequence
    end

    def root
      @sequence.root
    end

    # Barriers

    def self.read_barrier(*values)
      define_method(:read_barrier)  { Set.new(values) }
    end

    def read_barrier
      Set[]
    end

    def self.write_barrier(*values)
      define_method(:write_barrier) { Set.new(values) }
    end

    def write_barrier
      Set[]
    end

    # Stream manipulation

    def read(io)
      if respond_to? :body
        @body = self.class.const_get(:Body).new(:parent => @sequence)
        @body.read(io)
      end
    end

    def write(io)
      io.write([ instruction ].pack("C"))

      if respond_to? :body
        @body.write(io)
      end
    end

    def byte_length
      if respond_to? :body
        @body.byte_length + 1
      else
        1
      end
    end

    def offset
      @sequence.offset_of(self)
    end

    def next
      @sequence.opcode_at(offset + byte_length)
    end

    # Attributes

    def ast_type
      self.class.mnemonic.
        gsub(/^[A-Z]/) { |m| m[0].downcase }.
        gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }
    end

    def consumes_context
      false
    end

    def parameters
      []
    end

    def metadata
      {
        label:         offset,
        read_barrier:  read_barrier,
        write_barrier: write_barrier,
      }
    end

    # Disassembling

    def disassemble_parameters
      @body.to_hash if @body
    end

    def disassemble
      "   #{offset.to_s.rjust(4, "0")}  #{self.class.mnemonic.rjust(20, " ")} #{disassemble_parameters}"
    end
    alias :inspect :disassemble
  end
end

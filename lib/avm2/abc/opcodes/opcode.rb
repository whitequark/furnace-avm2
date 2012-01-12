module AVM2::ABC
  class Opcode
    MAP = {}

    def self.define_property(name, options={}, &block)
      define_singleton_method(name) do |value=nil, &value_block|
        if value_block
          define_method(name) do
            instance_exec &value_block
          end
        elsif value
          define_method(name) do
            value
          end
        else
          define_method(name) do
            true
          end
        end

        instance_exec(value, &block) if block
      end
    end

    def self.body(&block)
      @body_defined = true

      klass = Class.new(Record) do
        instance_exec &block
      end
      const_set :Body, klass

      attr_accessor :body
    end

    define_property :instruction do |encoding|
      MAP[encoding] = self
    end

    define_property :consume
    define_property :produce

    define_property :type

    attr_reader :sequence

    def initialize(sequence)
      @sequence = sequence
    end

    def read(io)
      if respond_to? :body
        @body = self.class.const_get(:Body).new
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
      0
    end

    def mnemonic
      self.class.to_s
    end

    def disassemble_parameters
      @body.to_hash if @body
    end

    def disassemble
      "   #{offset.to_s.rjust(4, "0")}  #{mnemonic.ljust(35)} #{disassemble_parameters}"
    end
    alias :inspect :disassemble
  end
end
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

    def do_read(io)
      @body = self.class.const_get(:Body).read(io) if respond_to? :body
    end

    def do_write(io)
      @body.do_write(io) if respond_to? :body
    end

    def mnemonic
      BinData::RegisteredClasses.underscore_name(self.class.to_s)
    end

    def disassemble
      "   #{offset.to_s.rjust(4, "0")}  #{mnemonic.ljust(25)} #{disassemble_parameters}"
    end

    def disassemble_parameters
      snapshot.map { |k,v| "#{k}: #{v}" }.join(", ")
    end

    def offset
      0
    end
  end
end
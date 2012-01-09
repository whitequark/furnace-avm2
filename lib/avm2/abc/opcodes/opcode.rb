module AVM2::ABC
  class Opcode < Record
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

    # Magic.
    hide  :instruction
    uint8 :instruction

    define_property :instruction do |encoding|
      MAP[encoding] = self
    end

    define_property :consume
    define_property :produce

    define_property :type

    def mnemonic
      BinData::RegisteredClasses.underscore_name(self.class.to_s)
    end

    def disassemble
      "   #{rel_offset.to_s.rjust(4, "0")}  #{mnemonic.ljust(25)} #{disassemble_parameters}"
    end

    def disassemble_parameters
      snapshot.map { |k,v| "#{k}: #{v}" }.join(", ")
    end
  end
end
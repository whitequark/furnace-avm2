module AVM2::ABC
  class Opcode < Record
    INSTRUCTIONS = {}

    def self.define_property(name)
      define_singleton_method(name) do |value=nil, &block|
        if value.nil?
          instance_variable_get(:"@#{name}")
        else
          instance_variable_set(:"@#{name}", value)

          block.call(value) if block
        end
      end

      define_method(name) do
        self.class.send(name)
      end
    end

    define_property :instruction do |encoding|
      INSTRUCTIONS[encoding] = self
    end

    define_property :stack_pop
    define_property :stack_push
  end
end
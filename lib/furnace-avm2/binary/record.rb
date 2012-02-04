module Furnace::AVM2::Binary
  class Record
    class << self
      attr_reader :format, :codebase

      def inherited(klass)
        Record.register klass

        klass.class_exec do
          @format = []
        end
      end

      def method_missing(method, name, options={}, &block)
        if instance_methods.include? :"read_#{method}"
          options.merge!(:block => block) if block

          check(method, options)

          attr_accessor name
          @format << [method, name, options.freeze]
        else
          super
        end
      end

      def register(klass)
        @codebase ||= []
        @codebase << klass
      end

      def codegen_each
        Record.codebase.each do |klass|
          klass.codegen
        end
      end

      def codegen
        tracing = $avm2_binary_trace

        gen_if = lambda do |code, options, &block|
          if options.include? :if
            if options[:if].to_proc.arity == 0
              code << "if instance_exec(&options[:if])"
            else
              code << "if instance_exec(self, &options[:if])"
            end
          end

          block.call(code)

          if options.include? :if
            code << "end"
          end
        end

        gen_read = lambda do |index|
          method, name, options = @format[index]
          code = []

          code << "options = self.class.format[#{index}][2]"

          gen_if.(code, options) do
            code << "self.class.trace_scope(#{name}) do" if tracing
            code << "  value = read_#{method}(io, options)"
            code << "  self.class.trace_value(value)" if tracing
            code << "  @#{name} = value"
            code << "end" if tracing
          end

          code.join "\n"
        end

        gen_write = lambda do |index|
          method, name, options = @format[index]
          code = []

          code << "options = self.class.format[#{index}][2]"

          gen_if.(code, options) do
            code << "self.class.trace_scope(#{name}) do" if tracing
            if options.include? :value
              code << "value = fetch(options[:value])"
            else
              code << "value = @#{name}"
            end
            code << "  self.class.trace_value(value)" if tracing
            code << "  value = write_#{method}(io, value, options)"
            code << "end" if tracing
          end

          code.join "\n"
        end

        class_eval <<-CODE, "(generated-io:#{self})"
        def initialize(options={})
          @root = options[:parent].root if options[:parent]
          #{@format.map { |f| "@#{f[1]} = nil\n" }.join}

          #{"initialize_record(options)" if instance_methods.include? :initialize_record}
        end

        def read(io)
          #{"before_read(io)" if instance_methods.include? :before_read}
          #{@format.each_index.map { |index| gen_read.(index) }.join "\n"}
          #{"after_read(io)" if instance_methods.include? :after_read}
        end

        def write(io)
          #{"before_write(io)" if instance_methods.include? :before_write}
          #{@format.each_index.map { |index| gen_write.(index) }.join "\n"}
          #{"after_write(io)" if instance_methods.include? :after_write}
          end
        CODE
      end

      attr_accessor :tracing

      def trace
        AVM2::Binary::Record.tracing = true

        yield
      ensure
        AVM2::Binary::Record.tracing = false
      end

      def trace_scope(scope)
        Thread.current[:binary_trace_scope] ||= []
        Thread.current[:binary_trace_scope].push scope
        Thread.current[:binary_trace_nested] = false

        yield
      ensure
        Thread.current[:binary_trace_scope].pop
        Thread.current[:binary_trace_nested] = true
      end

      def trace_value(value)
        return if value.is_a?(Array) && value[0].is_a?(Record)

        puts "#{Thread.current[:binary_trace_scope].join(".")} = #{value}"
      end
    end

    attr_reader :root

    def to_hash
      hash = {}

      self.class.format.each do |method, name, options|
        hash[name] = instance_variable_get :"@#{name}"
      end

      hash
    end

    def inspect
      to_hash.inspect
    end

    def byte_length
      self.class.format.map do |method, name, options|
        send(:"length_#{method}", instance_variable_get(:"@#{name}"), options)
      end.reduce(0, :+)
    end

    protected

    # uint8

    def read_uint8(io, options)
      io.read(1).unpack("C").at(0)
    end

    def write_uint8(io, value, options)
      io.write([value].pack("C"))
    end

    def length_uint8(value, options)
      1
    end

    # uint16

    def read_uint16(io, options)
      io.read(2).unpack("v").at(0)
    end

    def write_uint16(io, value, options)
      io.write([value].pack("v"))
    end

    def length_uint16(value, options)
      2
    end

    # int24

    def read_int24(io, options)
      lo, hi = io.read(3).unpack("vC")
      value = lo | (hi << 16)
      if value & 0x800000 != 0
        -(-value & 0x7fffff)
      else
        value
      end
    end

    def write_int24(io, value, options)
      lo, hi = value & 0xffff, (value >> 16) & 0xff
      io.write([lo, hi].pack("vC"))
    end

    def length_int24(value, options)
      3
    end

    # double

    def read_double(io, options)
      io.read(8).unpack("E").at(0)
    end

    def write_double(io, value, options)
      io.write([value].pack("E"))
    end

    def length_double(value, options)
      8
    end

    # vint32

    def read_vint32(io, options)
      read_vint(io, true)
    end

    def write_vint32(io, value, options)
      write_vint(io, value, true)
    end

    def length_vint32(value, options)
      length_vint(value)
    end

    # vuint32

    def read_vuint32(io, options)
      read_vint(io, false)
    end

    def write_vuint32(io, value, options)
      write_vint(io, value, true)
    end

    def length_vuint32(value, options)
      length_vint(value)
    end

    # vuint30

    def read_vuint30(io, options)
      read_vint(io, false)
    end

    def write_vuint30(io, value, options)
      write_vint(io, value, true)
    end

    def length_vuint30(value, options)
      length_vint(value)
    end

    # vstring

    def read_vstring(io, options)
      length = read_vuint32(io, {})
      io.read(length)
    end

    def write_vstring(io, value, options)
      write_vuint32(io, value.bytesize, {})
      io.write(value)
    end

    # nested

    def self.check_nested(options={})
      do_check(options, "nested", [:class])
    end

    def read_nested(io, options)
      nested = options[:class].new((options[:options] || {}).merge(:parent => self))
      nested.read(io)
      nested
    end

    def write_nested(io, value, options)
      if value.class != options[:class]
        raise Exception, "conflicting types in nested write: #{options[:class]} != #{value.class}"
      end

      value.write(io)
    end

    # array

    def self.check_array(options={})
      do_check(options, "array", [:initial_length, :type], [:options])

      check(options[:type], options[:options] || {})
    end

    def read_array(io, options)
      length = fetch(options[:initial_length])

      array = []
      length.times do |index|
        #self.class.trace_scope(index.to_s) do
          array << send(:"read_#{options[:type]}", io, options[:options])
        #end
      end
      array
    end

    def write_array(io, value, options)
      value.each do |element|
        send(:"write_#{options[:type]}", io, element, options[:options])
      end
    end

    def length_array(value, options)
      value.map do |element|
        send(:"length_#{options[:type]}", element, options[:options])
      end.reduce(0, :+)
    end

    # choice

    def self.check_choice(options={})
      do_check(options, "choice", [:selection, :block])

      options[:choice] = ChoiceDefinition.parse(options.delete(:block))
    end

    def read_choice(io, options)
      selection = fetch(options[:selection])

      options[:choice].each do |variant, type, sub_options|
        if selection == variant
          return send(:"read_#{type}", io, sub_options)
        end
      end

      raise Exception, "unknown choice value #{value}"
    end

    def write_choice(io, value, options)
      selection = fetch(options[:selection])

      options[:choice].each do |variant, type, sub_options|
        if selection == variant
          return send(:"write_#{type}", io, value, sub_options)
        end
      end

      raise Exception, "unknown choice value #{value}"
    end

    def length_choice(value)
      value.length
    end

    # Common

    def fetch(what)
      if what.respond_to? :call
        instance_exec &what
      elsif what.is_a? Symbol
        send what
      else
        raise Exception, "cannot fetch #{what.inspect}"
      end
    end

    def self.check(type, options)
      if respond_to? :"check_#{type}"
        send :"check_#{type}", options
      end
    end

    def self.do_check(original_options, name, mandatory=[], optional=[])
      options = original_options.clone

      mandatory.each do |arg|
        raise Exception, "#{name} records require #{arg.inspect} to be set" unless options.delete(arg)
      end

      optional.each do |arg|
        options.delete(arg)
      end

      # Global options
      options.delete(:if)

      if options.any?
        raise Exception, "extra options #{options.keys.inspect} for #{name} record"
      end
    end

    # Generics

    def read_vint(io, signed)
      value = 0
      bit_shift = 0

      begin
        byte = io.read(1).unpack("C").at(0)

        value |= (byte & 0x7F) << bit_shift
        bit_shift += 7
      end while byte & 0x80 != 0

      sign_bit = (1 << 31)
      if signed && (value & sign_bit) != 0
        value = value | (-1 << 32)
      end

      value
    end

    def write_vint(io, value, signed)
      value = value & 0xffffffff

      bytes = []

      begin
        byte = value & 0x7F
        value >>= 7

        if value != 0
          byte |= 0x80
        end

        bytes.push(byte)
      end while value != 0

      io.write bytes.pack("C*")
    end

    def length_vint(value)
      length = 0

      begin
        length += 1
        value >>= 7
      end while value != 0

      length
    end
  end
end
module Furnace::AVM2
  class Decompiler
    include Furnace::AST
    include Furnace::AVM2::ABC
    include Furnace::AVM2::Tokens

    def initialize(body, options)
      @body, @method, @options = body, body.method, options

      @locals   = Set.new([0]) + (1..@method.param_count).to_a
      @spurious = Set.new
    end

    def decompile
      @state   = :prologue
      @nodes   = []

      begin
        @opcodes = @body.code_to_ast.children

        while @opcodes.any?
          unless send :"on_#{@state}"
            comment = "Well, this is embarassing.\n\n" +
              "Stage `#{@state}' failed at:\n" +
              "#{@error.inspect}\n"

            if @opcodes.first != @error
              comment << "\nOpcode at the top of stack:\n" +
                "#{@opcodes.first.inspect}\n"
            end

            @nodes << CommentToken.new(@body, comment, @options)
            break
          end
        end
      rescue Exception => e
        @nodes << CommentToken.new(@body,
          "'Ouch!' cried I, then died.\n" \
          "#{e.class}: #{e.message}\n" \
          "#{e.backtrace[0..5].map { |l| "    #{l}\n"}.join}" \
          "      ... et cetera\n",
        @options)
      end

      @nodes
    end

    # Prologue

    Prologue = Matcher.new do
      [:push_scope,
        [:get_local, 0]]
    end

    def on_prologue
      if Prologue.match(@opcodes.first)
        @opcodes.shift
        @state = :expression
      else
        @error = @opcodes.first
      end
    end

    # Expressions

    def on_expression
      if [:nop, :jump_target].include? @opcodes.first.type
        @opcodes.shift
        true
      else
        catch(:unwind) do
          node = expression(@opcodes.first)
          node = token(DiscardToken, [node]) unless node.toplevel?
          @nodes << node

          @opcodes.shift
        end
      end
    end

    def expression(opcode)
      handler = :"expr_#{opcode.type}"
      if respond_to?(handler) && node = send(handler, opcode)
        node
      else
        @error = opcode
        throw :unwind
      end
    end
    alias :expr :expression

    def expressions(opcodes)
      opcodes.map do |opcode|
        expression opcode
      end
    end
    alias :exprs :expressions

    ## Immediates

    def expr_imm(opcode)
      case opcode.type
      when :integer, :double
        token(ImmediateToken, *opcode.children)
      when :null, :undefined, :true, :false
        token(ImmediateToken, opcode.type)
      end
    end
    alias :expr_integer   :expr_imm
    alias :expr_double    :expr_imm
    alias :expr_null      :expr_imm
    alias :expr_undefined :expr_imm
    alias :expr_true      :expr_imm
    alias :expr_false     :expr_imm

    def expr_string(opcode)
      string, = opcode.children
      token(ImmediateToken, string.inspect)
    end

    def expr_nan(opcode)
      token(ImmediateToken, "NaN")
    end

    def expr_new_array(opcode)
      token(ArrayToken, exprs(opcode.children))
    end

    def expr_new_object(opcode)
      token(ObjectToken, opcode.children.
        each_slice(2).map do |key, value|
          token(ObjectPairToken, [
            expr(key),
            expr(value)
          ])
        end)
    end

    ## Locals

    def local_name(index)
      if index == 0
        "this"
      elsif index <= @method.param_count
        if @method.has_param_names?
          @method.param_names[index - 1]
        else
          "param#{index - 1}"
        end
      else
        "local#{index - @method.param_count - 1}"
      end
    end

    def expr_get_local(opcode)
      index, = opcode.children
      token(VariableNameToken, local_name(index))
    end

    def expr_get_spurious(opcode)
      index, = opcode.children
      token(VariableNameToken, "sp#{index}")
    end

    CONVERT_COERCE_MAP = {
      :convert_i => 'int',
      :convert_u => 'uint',
      :convert_d => 'Number',
      :convert_s => 'String',
      :convert_o => 'Object',

      :coerce_a  => '*',
      :coerce_b  => 'Boolean',
      :coerce_s  => 'String',
    }

    IMMEDIATE_TYPE_MAP = {
      :integer   => 'int',
      :string    => 'String',
      :double    => 'Number',
      :true      => 'Boolean',
      :false     => 'Boolean',
    }

    def expr_set_var(name, value, declare)
      if CONVERT_COERCE_MAP.include?(value.type)
        inside = value.children.first
        type   = token(TypeToken, [
                   token(ImmediateTypenameToken, CONVERT_COERCE_MAP[value.type])
                 ])
      elsif IMMEDIATE_TYPE_MAP.include?(value.type)
        inside = value
        type   = token(TypeToken, [
                   token(ImmediateTypenameToken, IMMEDIATE_TYPE_MAP[value.type])
                 ])
      elsif value.type == :coerce
        inside_type, inside = value.children
        type   = token(TypeToken, [
                   token(MultinameToken, inside_type.metadata[:origin])
                 ])
      else
        inside = value
        type   = nil
      end

      if declare
        token(LocalVariableToken, [
          token(VariableNameToken, name),
          type,
          token(InitializationToken, [
            expr(inside)
          ])
        ])
      else
        token(AssignmentToken, [
          token(VariableNameToken, name),
          expr(inside)
        ])
      end
    end

    def expr_set_local(opcode)
      index, value = opcode.children

      expr_set_var(local_name(index), value, !@locals.include?(index))
    ensure
      @locals << index
    end

    def expr_set_spurious(opcode)
      index, value = opcode.children

      expr_set_var("sp#{index}", value, !@spurious.include?(index))
    ensure
      @spurious << index
    end

    ## Arithmetics

    PSEUDO_OPERATOR_MAP = {
      :increment   => [:"+", 1],
      :increment_i => [:"+", 1],
      :decrement   => [:"-", 1],
      :decrement_i => [:"-", 1],
    }

    def expr_pseudo_arithmetic(opcode)
      inside = expr(*opcode.children)
      inside = token(ParenthesesToken, [inside]) if inside.complex?

      operator, other_value = PSEUDO_OPERATOR_MAP[opcode.type]
      token(BinaryOperatorToken, [
        inside,
        token(ImmediateToken, other_value)
      ], operator)
    end

    alias :expr_increment   :expr_pseudo_arithmetic
    alias :expr_increment_i :expr_pseudo_arithmetic
    alias :expr_decrement   :expr_pseudo_arithmetic
    alias :expr_decrement_i :expr_pseudo_arithmetic

    OPERATOR_MAP = {
      :and         => :"&&",
      :or          => :"||",

      :add         => :"+",
      :add_i       => :"+",
      :subtract    => :"-",
      :subtract_i  => :"-",
      :multiply    => :"*",
      :multiply_i  => :"*",
      :divide      => :"/",
      :modulo      => :"%",
      :multiply    => :"*",
      :negate      => :"-",
      :negate_i    => :"-",

      :!           => :!,
      :>           => :>,
      :>=          => :>=,
      :<           => :<,
      :<=          => :<=,
      :==          => :==,
      :===         => :===,

      :bit_and     => :"&",
      :bit_or      => :"|",
      :bit_xor     => :"^",
      :bit_not     => :"~",
      :lshift      => :"<<",
      :rshift      => :">>",
      :urshift     => :">>>",
    }

    def expr_arithmetic(opcode)
      if OPERATOR_MAP.include?(opcode.type)
        insides = parenthesize(exprs(opcode.children))

        if insides.count == 1
          token(UnaryOperatorToken, insides, OPERATOR_MAP[opcode.type])
        elsif insides.count == 2
          token(BinaryOperatorToken, insides, OPERATOR_MAP[opcode.type])
        else
          token(CommentToken, "Unexpected #{insides.count}-ary operator")
        end
      end
    end

    alias :expr_and         :expr_arithmetic
    alias :expr_or          :expr_arithmetic

    alias :expr_add         :expr_arithmetic
    alias :expr_add_i       :expr_arithmetic
    alias :expr_subtract    :expr_arithmetic
    alias :expr_subtract_i  :expr_arithmetic
    alias :expr_multiply    :expr_arithmetic
    alias :expr_multiply_i  :expr_arithmetic
    alias :expr_divide      :expr_arithmetic
    alias :expr_modulo      :expr_arithmetic
    alias :expr_negate      :expr_arithmetic

    alias :expr_!           :expr_arithmetic
    alias :"expr_>"         :expr_arithmetic
    alias :"expr_>="        :expr_arithmetic
    alias :"expr_<"         :expr_arithmetic
    alias :"expr_<="        :expr_arithmetic
    alias :"expr_=="        :expr_arithmetic
    alias :"expr_==="       :expr_arithmetic

    alias :expr_bit_and     :expr_arithmetic
    alias :expr_bit_or      :expr_arithmetic
    alias :expr_bit_xor     :expr_arithmetic
    alias :expr_bit_not     :expr_arithmetic
    alias :expr_lshift      :expr_arithmetic
    alias :expr_rshift      :expr_arithmetic
    alias :expr_urshift     :expr_arithmetic

    ## Properties

    PropertyGlobal = Matcher.new do
      [any,
        [:find_property,
          capture(:multiname)],
        backref(:multiname),
        capture_rest(:arguments)]
    end

    PropertyStrict = Matcher.new do
      [any,
        [:find_property_strict,
          capture(:multiname)],
        backref(:multiname),
        capture_rest(:arguments)]
    end

    def expr_get_lex(opcode)
      multiname, = opcode.children
      get_name(nil, multiname)
    end

    def expr_get_property(opcode)
      subject, multiname, = opcode.children
      get_name(expr(subject), multiname)
    end

    def expr_set_property(opcode)
      if captures = PropertyGlobal.match(opcode)
        token(AssignmentToken, [
          get_name(nil, captures[:multiname]),
          expr(*captures[:arguments])
        ])
      else
        subject, multiname, value, = opcode.children
        token(AssignmentToken, [
          get_name(expr(subject), multiname),
          expr(value)
        ])
      end
    end
    alias :expr_init_property :expr_set_property

    def expr_delete_property(opcode)
      subject, multiname, = opcode.children
      token(DeleteToken, [get_name(expr(subject), multiname)])
    end

    def expr_do_property(opcode, klass)
      if captures = PropertyStrict.match(opcode)
        token(klass, [
          get_name(nil, captures[:multiname]),
          token(ArgumentsToken, exprs(captures[:arguments]))
        ])
      else
        subject, multiname, *args = opcode.children
        token(klass, [
          get_name(expr(subject), multiname),
          token(ArgumentsToken, exprs(args))
        ])
      end
    end

    def expr_call_property(opcode)
      expr_do_property(opcode, CallToken)
    end

    def expr_construct_property(opcode)
      expr_do_property(opcode, NewToken)
    end

    def expr_construct(opcode)
      type, *args = opcode.children
      token(NewToken, [
        expr(type),
        token(ArgumentsToken, exprs(args))
      ])
    end

    ## Control flow

    def expr_ternary_if(opcode)
      token(TernaryOperatorToken, parenthesize(exprs(opcode.children)))
    end

    def expr_return(opcode)
      token(ReturnToken, exprs(opcode.children))
    end
    alias :expr_return_void  :expr_return
    alias :expr_return_value :expr_return

    # Miscellanea

    def expr_as_type_late(opcode)
      token(AsToken, exprs(opcode.children))
    end

    def expr_is_type_late(opcode)
      token(IsToken, exprs(opcode.children))
    end

    def expr_jump(opcode)
      raise "no jumps yet :/"
    end
    alias :expr_jump_if :expr_jump

    private

    def token(klass, *args)
      klass.new(@body, *args, @options)
    end

    def get_name(subject, multiname)
      origin = multiname.metadata[:origin]
      case origin.kind
      when :QName, :Multiname
        if subject
          token(AccessToken, [
            subject,
            token(PropertyNameToken, origin.name)
          ])
        else
          token(PropertyNameToken, origin.name)
        end
      when :MultinameL
        if subject
          token(IndexToken, [
            subject,
            expr(multiname.children.last)
          ])
        else
          token(CommentToken, "%%type #{origin} with no subject")
        end
      else
        token(CommentToken, "%%type #{origin}")
      end
    end

    def parenthesize(what)
      what.map do |inside|
        if inside.complex?
          inside = token(ParenthesesToken, [inside])
        else
          inside
        end
      end
    end
  end
end
module Furnace::AVM2
  class Decompiler
    include Furnace::AST
    include Furnace::AVM2::ABC
    include Furnace::AVM2::Tokens

    class ExpressionNotRecognized < StandardError
      attr_reader :context, :opcode

      def initialize(context, opcode)
        @context, @opcode = context, opcode
      end
    end

    def initialize(body, options)
      @body, @method, @options = body, body.method, options
    end

    def decompile
      begin
        @locals = Set.new([0]) + (1..@method.param_count).to_a

        @nf = @body.code_to_nf

        stmt_block @nf, function: true
      rescue Exception => e
        comment = "'Ouch!' cried I, then died.\n" +
          "#{e.class}: #{e.message}\n" +
          "#{e.backtrace[0..5].map { |l| "    #{l}\n"}.join}" +
          "      ... et cetera\n"

        token(ScopeToken, [
          token(CommentToken, comment)
        ], function: true)
      end
    end

    # Statements

    Prologue = Matcher.new do
      [:push_scope,
        [:get_local, 0]]
    end

    def stmt_block(block, options={})
      nodes = []

      block.children.each do |opcode|
        if (opcode.type == :push_scope && Prologue.match(opcode))
          # Ignore these
          next
        end

        case opcode.type
        when :if
          condition, if_true, if_false = opcode.children

          nodes << token(IfToken, handle_expression(condition),
            stmt_block(if_true, continuation: !if_false.nil?))
          nodes << token(ElseToken,
            stmt_block(if_false)) if if_false

        when :label
          name, = opcode.children

          nodes << token(LabelDeclarationToken, name)

        when :while
          condition, body = opcode.children

          nodes << token(WhileToken, handle_expression(condition),
            stmt_block(body))

        when :for_in
          value_reg, value_type, object_reg, body = opcode.children

          @locals.add(value_reg)

          nodes << token(ForToken,
            token(InToken, [
              token(LocalVariableToken, [
                token(VariableNameToken, local_name(value_reg)),
                token(TypeToken, [
                  token(MultinameToken, value_type.metadata[:origin])
                ]),
              ]),
              token(VariableNameToken, local_name(object_reg)),
            ]),
            stmt_block(body))

        when :break
          nodes << token(ReturnToken, exprs(opcode.children))

        when :continue
          nodes << token(ContinueToken, exprs(opcode.children))

        when :return_value, :return_void
          nodes << token(ReturnToken, exprs(opcode.children))

        else
          node = handle_expression(opcode)
          node = token(StatementToken, [node])
          nodes << node
        end
      end

    rescue ExpressionNotRecognized => e
      comment = "Well, this is embarassing.\n\n" +
        "Expression recognizer failed at:\n" +
        "#{e.opcode.inspect}\n"

      if e.context != e.opcode
        comment << "\nOpcode at the top of stack:\n" +
          "#{e.context.inspect}\n"
      end

      nodes << CommentToken.new(@body, comment, @options)

    ensure
      unless $! && !$!.is_a?(ExpressionNotRecognized)
        return token(ScopeToken, nodes,
          continuation: options[:continuation],
          function:     options[:function])
      end
    end

    # Expressions

    def handle_expression(opcode)
      expression(opcode)
    rescue ExpressionNotRecognized => e
      raise ExpressionNotRecognized.new(opcode, e.opcode)
    end

    def expression(opcode)
      handler = :"expr_#{opcode.type}"
      if respond_to?(handler) && node = send(handler, opcode)
        node
      else
        raise ExpressionNotRecognized.new(nil, opcode)
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
      if index < 0
        "sp#{-index}"
      elsif index == 0
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

    ## Arithmetics

    INPLACE_OPERATOR_MAP = {
      :inc_local   => :"++",
      :inc_local_i => :"++",
      :dec_local   => :"--",
      :dec_local_i => :"--",
    }

    def expr_inplace_arithmetic(opcode)
      token(UnaryPostOperatorToken, [
        token(VariableNameToken, local_name(*opcode.children)),
      ], INPLACE_OPERATOR_MAP[opcode.type])
    end

    alias :expr_inc_local   :expr_inplace_arithmetic
    alias :expr_inc_local_i :expr_inplace_arithmetic
    alias :expr_dec_local   :expr_inplace_arithmetic
    alias :expr_dec_local_i :expr_inplace_arithmetic

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
      :!=          => :!=,
      :"!=="       => :"!==",

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
        insides = parenthesize_each(exprs(opcode.children))

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
    alias :"expr_!="        :expr_arithmetic
    alias :"expr_!=="       :expr_arithmetic

    alias :expr_bit_and     :expr_arithmetic
    alias :expr_bit_or      :expr_arithmetic
    alias :expr_bit_xor     :expr_arithmetic
    alias :expr_bit_not     :expr_arithmetic
    alias :expr_lshift      :expr_arithmetic
    alias :expr_rshift      :expr_arithmetic
    alias :expr_urshift     :expr_arithmetic

    def expr_in(opcode)
      token(InToken, parenthesize_each(exprs(opcode.children)))
    end

    ## Properties and objects

    This = Matcher.new do
      [:get_local, 0]
    end

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

    def expr_get_super(opcode)
      subject, multiname, = opcode.children
      if This.match subject
        get_name(token(SuperToken), multiname)
      end
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

    def expr_set_super(opcode)
      subject, multiname, value = opcode.children
      if This.match subject
        token(AssignmentToken, [
          get_name(token(SuperToken), multiname),
          expr(value)
        ])
      end
    end

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

    def expr_call_super(opcode)
      subject, multiname, *args = opcode.children
      if This.match subject
        token(CallToken, [
          get_name(token(SuperToken), multiname),
          token(ArgumentsToken, exprs(args))
        ])
      end
    end

    ## Object creation

    def expr_construct_property(opcode)
      expr_do_property(opcode, NewToken)
    end

    def expr_construct(opcode)
      type, *args = opcode.children
      token(NewToken, [
        parenthesize(expr(type)),
        token(ArgumentsToken, exprs(args))
      ])
    end

    def expr_construct_super(opcode)
      subject, *args = opcode.children
      if This.match subject
        token(CallToken, [
          token(SuperToken),
          token(ArgumentsToken, exprs(args))
        ])
      end
    end

    ## Control flow

    def expr_ternary(opcode)
      token(TernaryOperatorToken, parenthesize_each(exprs(opcode.children)))
    end

    # See /src/java/macromedia/asc/semantics/CodeGenerator.java
    # If this looks stupid to you, that's because it IS stupid.
    CallThisGlobal = Matcher.new do
      [:get_global_scope]
    end

    CallThisLocal = Matcher.new do
      [ either[:get_scope_object, :get_local], 0 ]
    end

    def expr_call(opcode)
      subject, this, *args = opcode.children

      subject_token = token(AccessToken, [
        parenthesize(expr(subject)),
        token(PropertyNameToken, "call")
      ])

      if CallThisGlobal.match(this) || CallThisLocal.match(this)
        # FUCK YOU!
        token(CallToken, [
          subject_token,
          token(ArgumentsToken, [
            token(VariableNameToken, "this"),
            *exprs(args)
          ])
        ])
      else
        token(CallToken, [
          subject_token,
          token(ArgumentsToken, exprs([
            this,
            *args
          ]))
        ])
      end
    end

    def expr_throw(opcode)
      token(ThrowToken, exprs(opcode.children))
    end

    ## Types

    def expr_as_type_late(opcode)
      token(AsToken, parenthesize_each(exprs(opcode.children)))
    end

    def expr_is_type_late(opcode)
      token(IsToken, parenthesize_each(exprs(opcode.children)))
    end

    def expr_type_of(opcode)
      token(TypeOfToken, exprs(opcode.children))
    end

    def expr_apply_type(opcode)
      base, *args = opcode.children
      token(GenericTypeToken, [
        expr(base),
        token(GenericSpecializersToken,
          exprs(args))
      ])
    end

    def expr_passthrough(opcode)
      expr(*opcode.children)
    end
    alias :expr_coerce_a :expr_passthrough
    alias :expr_coerce_b :expr_passthrough
    alias :expr_coerce_s :expr_passthrough

    def expr_coerce(opcode)
      typename, subject, = opcode.children
      expr(subject)
    end

    def expr_convert(opcode)
      token(CallToken, [
        token(ImmediateTypenameToken, CONVERT_COERCE_MAP[opcode.type]),
        token(ArgumentsToken, exprs(opcode.children))
      ])
    end
    alias :expr_convert_i :expr_convert
    alias :expr_convert_u :expr_convert
    alias :expr_convert_d :expr_convert
    alias :expr_convert_s :expr_convert
    alias :expr_convert_o :expr_convert

    private

    def token(klass, *args)
      if args.last.is_a? Hash
        options = @options.merge(args.pop)
      else
        options = @options
      end

      klass.new(@body, *args, options)
    end

    def get_name(subject, multiname)
      origin = multiname.metadata[:origin]
      case origin.kind
      when :QName, :QNameA, :Multiname, :MultinameA
        if subject
          token(AccessToken, [
            parenthesize(subject),
            token(PropertyNameToken, origin.name)
          ])
        else
          token(PropertyNameToken, origin.name)
        end
      when :MultinameL, :MultinameLA
        if subject
          token(IndexToken, [
            parenthesize(subject),
            expr(multiname.children.last)
          ])
        else
          token(CommentToken, "%%type #{origin} with no subject")
        end
      when :RTQName, :RTQNameA
        token(RTNameToken, [
          parenthesize(expr(multiname.children.first)),
          token(PropertyNameToken, origin.name)
        ])
      else
        token(CommentToken, "%%type #{origin}")
      end
    end

    def parenthesize(what)
      if what.complex?
        token(ParenthesesToken, [what])
      else
        what
      end
    end

    def parenthesize_each(what)
      what.map do |inside|
        parenthesize(inside)
      end
    end
  end
end
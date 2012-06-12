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
      @body, @method, @options = body, body.method, options.dup
      @closure = @options.delete(:closure)
    end

    ActivationPrologue = Matcher.new do
      [:begin,
        maybe[
          [:push_scope,
            [:get_local, 0]],
        ],
        [:set_local, -1,
          [:new_activation]],
        [:set_local, capture(:activation_local),
          [:get_local, -1]],
        [:push_scope,
          [:get_local, -1]],
        skip
      ]
    end

    RegularPrologue = Matcher.new do
      [:begin,
        [:push_scope,
          [:get_local, 0]],
        skip
      ]
    end

    def decompile
      begin
        @locals = Set.new([0]) + (1..@method.param_count).to_a
        @scopes = []

        @nf = @body.code_to_nf

        if captures = ActivationPrologue.match(@nf)
          @closure_slots = {}
          @body.slot_traits.each do |trait|
            @closure_slots[trait.idx] = trait
          end

          @closure_locals = Set.new

          # Also a regular function
          if RegularPrologue.match @nf
            @scopes << :this
            @nf.children.slice! 0...1
          end

          @scopes << :activation
          @nf.children.slice! 0...3
        elsif RegularPrologue.match @nf
          @scopes << :this
          @nf.children.slice! 0...1
        else
          # No prologue at all, probably closure-less closure
        end

        @global_slots = @options[:global_slots] || {}

        stmt_block @nf,
          function: !@options[:global_code],
          closure:  @closure

      rescue Exception => e
        @failed = true

        comment = "'Ouch!' cried I, then died.\n" +
          "#{e.class}: #{e.message}\n" +
          "#{e.backtrace[0..5].map { |l| "    #{l}\n"}.join}" +
          "      ... et cetera\n"

        token(ScopeToken, [
          token(CommentToken, comment)
        ], function: !@options[:global_code],
           closure:  @closure)

      ensure
        if stat = @options[:stat]
          stat[:total] += 1

          if @failed
            stat[:failed]  += 1
          elsif @partial
            stat[:partial] += 1
          else
            stat[:success] += 1
          end
        end
      end
    end

    # Statements

    def stmt_block(block, options={})
      nodes = []
      last_index = 0

      block.children.each_with_index do |opcode, index|
        last_index = index

        if respond_to?(:"stmt_#{opcode.type}")
          send :"stmt_#{opcode.type}", opcode, nodes
        else
          catch(:skip) do
            @collected_vars = []
            stmt = token(StatementToken, [
              handle_expression(opcode)
            ])

            nodes.concat @collected_vars
            nodes.push stmt
          end
        end
      end

    rescue ExpressionNotRecognized => e
      @partial = true

      comment = "Well, this is embarassing.\n\n" +
        "Expression recognizer failed at:\n" +
        "#{e.opcode.inspect}\n"

      comment << "\nRest of the code in this block:\n"
      block.children[last_index..-1].each do |opcode|
        comment << "#{opcode.inspect}\n"
      end

      nodes << CommentToken.new(@body, comment, @options)

    ensure
      if $!.nil? || $!.is_a?(ExpressionNotRecognized)
        return token(ScopeToken, nodes, options)
      end
    end

    def stmt_if(opcode, nodes)
      condition, if_true, if_false = opcode.children

      nodes << token(IfToken, handle_expression(condition),
        stmt_block(if_true, continuation: !if_false.nil?))

      if if_false
        first_child = if_false.children.first
        if if_false.children.count == 1 &&
              first_child.type == :if
          nodes << token(ElseToken,
            nil)
          stmt_if(first_child, nodes)
        else
          nodes << token(ElseToken,
            stmt_block(if_false))
        end
      end
    end

    def stmt_label(opcode, nodes)
      name, = opcode.children

      nodes << token(LabelDeclarationToken, name)
    end

    def stmt_while(opcode, nodes)
      condition, body = opcode.children

      nodes << token(WhileToken, handle_expression(condition),
        stmt_block(body))
    end

    def stmt_for(opcode, nodes)
      value_reg, value_type, object_reg, body = opcode.children

      @locals.add(value_reg)

      if opcode.type == :for_in
        klass = ForToken
      elsif opcode.type == :for_each_in
        klass = ForEachToken
      end

      if @closure_slots
        name = token(VariableNameToken, @closure_slots[value_reg].name.name)
      else
        name = token(VariableNameToken, local_name(value_reg))
      end

      nodes << token(klass,
        token(InToken, [
          token(LocalVariableToken, [
            name,
            type_token(value_type)
          ]),
          token(VariableNameToken, local_name(object_reg)),
        ]),
        stmt_block(body))
    end
    alias :stmt_for_in      :stmt_for
    alias :stmt_for_each_in :stmt_for

    def stmt_break(opcode, nodes)
      nodes << token(ReturnToken, exprs(opcode.children))
    end

    def stmt_continue(opcode, nodes)
      nodes << token(ContinueToken, exprs(opcode.children))
    end

    def stmt_throw(opcode, nodes)
      nodes << token(ThrowToken, exprs(opcode.children))
    end

    def stmt_return(opcode, nodes)
      nodes << token(ReturnToken, exprs(opcode.children))
    end
    alias :stmt_return_value :stmt_return
    alias :stmt_return_void  :stmt_return

    def stmt_push_scope(opcode, nodes)
      if @options[:global_code]
        @scopes.push opcode.children.first
      else
        raise "pushscope in nonglobal code"
      end
    end

    def stmt_pop_scope(opcode, nodes)
      if @options[:global_code]
        @scopes.pop
      else
        raise "popscope in nonglobal code"
      end
    end

    # Expressions

    def handle_expression(opcode)
      expression(opcode, true)
    rescue ExpressionNotRecognized => e
      raise ExpressionNotRecognized.new(opcode, e.opcode)
    end

    def expression(opcode, toplevel=false)
      if toplevel
        handler = :"expr_#{opcode.type}_toplevel"
        if respond_to?(handler) && node = send(handler, opcode)
          return node
        end
      end

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
        if @options[:static]
          @options[:instance].name.name
        else
          "this"
        end
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

    GetSlot = Matcher.new do
      [:get_slot,
        capture(:index),
        either[
          [:get_scope_object, capture(:scope_pos)],
          [:get_global_scope]
        ]
      ]
    end

    def expr_get_slot(opcode)
      if captures = GetSlot.match(opcode)
        scope = @scopes[captures[:scope_pos] || 0]
        if @closure_slots && scope == :activation
          # treat as a local variable
          slot = @closure_slots[captures[:index]]
          token(VariableNameToken, slot.name.name)
        elsif scope == :this
          # treat as a global property
          if slot = @global_slots[captures[:index]]
            get_name(nil, slot.name.to_astlet)
          else
            token(PropertyNameToken,
              "$__GLOBAL_#{captures[:index]}")
          end
        end
      end
    end

    IMMEDIATE_TYPE_MAP = {
      :any       => '*',
      :integer   => 'int',
      :unsigned  => 'uint',
      :string    => 'String',
      :double    => 'Number',
      :object    => 'Object',
      :boolean   => 'Boolean',
      :true      => 'Boolean',
      :false     => 'Boolean',
    }

    def type_token(type)
      if IMMEDIATE_TYPE_MAP.include?(type)
        token(TypeToken, [
          token(ImmediateTypenameToken, IMMEDIATE_TYPE_MAP[type])
        ])
      else
        token(TypeToken, [
          token(MultinameToken, type.metadata[:origin])
        ])
      end
    end

    XmlLiteralPreMatcher = Matcher.new do
      [:coerce, [:q, "XML"], any]
    end

    def expr_set_var(name, value, type, declare, toplevel)
      if declare
        declaration =
          token(LocalVariableToken, [
            token(VariableNameToken, name),
            type
          ])
      end

      if declare && toplevel
        declaration.children <<
          token(InitializationToken, [
            expr(value)
          ])

        declaration
      else
        if declare
          @collected_vars <<
            token(StatementToken, [
              declaration
            ])
        end

        token(AssignmentToken, [
          token(VariableNameToken, name),
          parenthesize(expr(value))
        ])
      end
    end

    def expr_set_local(opcode, toplevel=false)
      index, value = opcode.children
      if IMMEDIATE_TYPE_MAP.include?(value.type)
        type = token(TypeToken, [
          token(ImmediateTypenameToken, IMMEDIATE_TYPE_MAP[value.type])
        ])
      elsif XmlLiteralPreMatcher.match value
        # XML literals work through expr_coerce
        type  = type_token(value.children.first)
        value = value
      elsif value.type == :coerce || value.type == :convert
        # Don't emit spurious coercion; typed variables already
        # imply it
        type  = type_token(value.children.first)
        value = value.children.last
      end

      expr_set_var(local_name(index), value, type, !@locals.include?(index), toplevel)
    ensure
      @locals.add index if index
    end

    def expr_set_local_toplevel(opcode)
      expr_set_local(opcode, true)
    end

    SetSlot = Matcher.new do
      [:set_slot,
        capture(:index),
        either[
          [:get_scope_object, capture(:scope_pos)],
          [:get_global_scope]
        ],
        capture(:value)
      ]
    end

    def expr_set_slot(opcode, toplevel=false)
      if captures = SetSlot.match(opcode)
        scope = @scopes[captures[:scope_pos] || 0]
        if @closure_slots && scope == :activation
          # treat as a local variable
          index, value = captures.values_at(:index, :value)
          slot = @closure_slots[index]

          type = type_token(slot.type.to_astlet) if slot.type
          expr = expr_set_var(slot.name.name, value, type,
                !@closure_locals.include?(index), toplevel)
          @closure_locals.add index

          expr
        elsif scope == :this
          # treat as a global property
          index, value = captures.values_at(:index, :value)

          if slot = @global_slots[index]
            name = get_name(nil, slot.name.to_astlet)
          else
            name = token(PropertyNameToken, "$__GLOBAL_#{index}")
          end

          token(AssignmentToken, [
            name,
            parenthesize(expr(value))
          ])
        end
      end
    end

    def expr_set_slot_toplevel(opcode)
      expr_set_slot(opcode, true)
    end

    ## Arithmetics

    INPLACE_OPERATOR_MAP = {
      :inc_local   => :"++",
      :dec_local   => :"--",
    }

    def expr_inplace_arithmetic(opcode)
      token(UnaryPostOperatorToken,
        token(VariableNameToken, local_name(*opcode.children)),
      INPLACE_OPERATOR_MAP[opcode.type])
    end

    alias :expr_inc_local :expr_inplace_arithmetic
    alias :expr_dec_local :expr_inplace_arithmetic

    PSEUDO_OPERATOR_MAP = {
      :increment   => [:"+", 1],
      :decrement   => [:"-", 1],
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
    alias :expr_decrement   :expr_pseudo_arithmetic

    def expr_prepost_incdec_local(opcode)
      index, = opcode.children
      lvar = token(VariableNameToken, local_name(index))

      if opcode.type == :post_increment_local
        token(UnaryPostOperatorToken, lvar, "++")
      elsif opcode.type == :post_decrement_local
        token(UnaryPostOperatorToken, lvar, "--")
      elsif opcode.type == :pre_increment_local
        token(UnaryOperatorToken, lvar, "++")
      elsif opcode.type == :pre_decrement_local
        token(UnaryOperatorToken, lvar, "--")
      end
    end
    alias :expr_post_increment_local :expr_prepost_incdec_local
    alias :expr_post_decrement_local :expr_prepost_incdec_local
    alias :expr_pre_increment_local  :expr_prepost_incdec_local
    alias :expr_pre_decrement_local  :expr_prepost_incdec_local

    OPERATOR_MAP = {
      :and         => :"&&",
      :or          => :"||",

      :add         => :"+",
      :subtract    => :"-",
      :multiply    => :"*",
      :divide      => :"/",
      :modulo      => :"%",
      :multiply    => :"*",
      :negate      => :"-",

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
          token(UnaryOperatorToken, insides.first, OPERATOR_MAP[opcode.type])
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
    alias :expr_subtract    :expr_arithmetic
    alias :expr_multiply    :expr_arithmetic
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
        either_multi[
          [
            [ either[:find_property, :find_property_strict],
                  capture(:multiname)],
            backref(:multiname),
          ],
          [
            [:find_property_strict,
              [:m, [:set, any], any]],
            capture(:multiname)
          ],
          [
            either[
              [:get_scope_object, 0],
              [:get_global_scope]
            ],
            capture(:multiname)
          ],
        ],
        capture_rest(:arguments)]
    end

    def expr_get_lex(opcode)
      multiname, = opcode.children
      get_name(nil, multiname)
    end

    def expr_get_property(opcode)
      if captures = PropertyGlobal.match(opcode)
        get_name(nil, captures[:multiname])
      else
        subject, multiname, = opcode.children
        get_name(expr(subject), multiname)
      end
    end

    def expr_get_super(opcode)
      subject, multiname, = opcode.children

      stmt = get_name(token(SuperToken), multiname)

      unless This.match subject
        stmt = token(SupplementaryCommentToken,
          "subject != this: #{subject.inspect}",
          [ stmt ])
      end

      stmt
    end

    def expr_set_property(opcode)
      if captures = PropertyGlobal.match(opcode)
        token(AssignmentToken, [
          get_name(nil, captures[:multiname]),
          parenthesize(expr(*captures[:arguments]))
        ])
      else
        subject, multiname, value, = opcode.children
        token(AssignmentToken, [
          get_name(expr(subject), multiname),
          parenthesize(expr(value))
        ])
      end
    end
    alias :expr_init_property :expr_set_property

    def expr_set_super(opcode)
      subject, multiname, value = opcode.children

      stmt = token(AssignmentToken, [
        get_name(token(SuperToken), multiname),
        parenthesize(expr(value))
      ])

      unless This.match subject
        stmt = token(SupplementaryCommentToken,
          "subject != this: #{subject.inspect}",
          [ stmt ])
      end

      stmt
    end

    def expr_do_property(opcode, klass, has_args)
      if captures = PropertyGlobal.match(opcode)
        token(klass, [
          get_name(nil, captures[:multiname]),
          (token(ArgumentsToken, exprs(captures[:arguments])) if has_args)
        ])
      else
        subject, multiname, *args = opcode.children
        token(klass, [
          get_name(expr(subject), multiname),
          (token(ArgumentsToken, exprs(args)) if has_args)
        ])
      end
    end

    def expr_delete_property(opcode)
      expr_do_property(opcode, DeleteToken, false)
    end

    def expr_call_property(opcode)
      expr_do_property(opcode, CallToken, true)
    end
    alias :expr_call_property_lex :expr_call_property

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
      expr_do_property(opcode, NewToken, true)
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
            token(VariableNameToken, local_name(0)),
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

    ## Types

    def expr_as_type_late(opcode)
      token(AsToken, parenthesize_each(exprs(opcode.children)))
    end

    def expr_is_type_late(opcode)
      token(IsToken, parenthesize_each(exprs(opcode.children)))
    end

    def expr_instance_of(opcode)
      token(InstanceOfToken, parenthesize_each(exprs(opcode.children)))
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

    def expr_new_class(opcode)
      throw :skip
    end

    def expr_convert(opcode)
      type, subject = opcode.children
      token(CallToken, [
        token(ImmediateTypenameToken, IMMEDIATE_TYPE_MAP[type]),
        token(ArgumentsToken, [
          expr(subject)
        ])
      ])
    end

    ## Closures

    def expr_new_function(opcode)
      index, = opcode.children
      body = @method.root.method_body_at(index)

      token(ClosureToken,
        body)
    end

    ## XML literals

    # FFFUUUUUUUUUU~~~
    XmlLiteralMatcher = Matcher.new do
      [:coerce, [:q, "XML"],
        [:construct,
          either[
            [:get_lex, [:q, "XML"]],
            [:get_property,
              [:find_property_strict, [:q, "XML"]], [:q, "XML"]]
          ],
          capture(:body),
        ]
      ]
    end

    def expr_coerce(opcode)
      if captures = XmlLiteralMatcher.match(opcode)
        # Oh, shit...
        token(XmlLiteralToken,
          xml_expr(captures[:body]))
      else
        typename, subject, = opcode.children
        expr(subject)
      end
    end

    def xml_expr(node)
      if respond_to?(:"xml_#{node.type}")
        send :"xml_#{node.type}", node
      else
        "{#{expr(node).to_text}}"
      end
    end

    def xml_string(node)
      node.children.first
    end

    def xml_add(node)
      node.children.map do |child|
        xml_expr child
      end.join
    end

    def xml_esc_xattr(node)
      xml_expr(node.children.first)
    end

    def xml_esc_xelem(node)
      xml_expr(node.children.first)
    end

    def expr_check_filter(node)
      content, = node.children
      expr(content)
    end

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
        elsif @scopes[0] == :this
          token(IndexToken, [
            token(VariableNameToken, "this"),
            expr(multiname.children.last)
          ])
        else
          token(CommentToken, "%%type #{origin} with no subject and non-this global-scope")
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
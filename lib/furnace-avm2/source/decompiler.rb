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

      @scopes       = []
      @metascopes   = []
      @catch_scopes = {}
    end

    def decompile
      begin
        @locals = Set.new([0]) + (1..@method.param_count).to_a

        @closure_locals = Set.new

        @closure_slots  = {}
        @body.slot_traits.each do |trait|
          @closure_slots[trait.idx] = trait
        end

        @global_slots = @options[:global_slots] || {}

        @scopes << :this if @options[:global_code]

        stmt_block (@nf || @body.code_to_nf),
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

    StaticProperty = Matcher.new do
      [ either[:set_property, :init_property],
        [:find_property, capture(:property)],
        backref(:property),
        capture(:value)
      ]
    end

    def decompose_static_initializer
      properties = {}
      matches = []

      @nf = @body.code_to_nf

      StaticProperty.find_all(@nf.children) do |match, captures|
        matches.push match

        begin
          token = handle_expression(captures[:value])
        rescue ExpressionNotRecognized => e
          token = token(CommentToken, "Unrecognized static initializer:\n#{e.opcode.inspect}")
        end

        properties[captures[:property]] = token
      end

      @nf.children -= matches

      properties
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

    def stmt_begin(opcode, nodes)
      nodes << stmt_block(opcode)
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

      nodes << token(WhileToken,
        handle_expression(condition),
        stmt_block(body))
    end

    def stmt_do_while(opcode, nodes)
      condition, body = opcode.children

      nodes << token(DoWhileToken,
        stmt_block(body, continuation: true),
        handle_expression(condition))
    end

    def stmt_for(opcode, nodes)
      value_reg, value_type, object_reg, body = opcode.children

      @locals.add(value_reg)

      if opcode.type == :for_in
        klass = ForToken
      elsif opcode.type == :for_each_in
        klass = ForEachToken
      end

      if @activation_local
        name = token(VariableNameToken, @closure_slots[value_reg].name.name)
      else
        name = local_token(value_reg)
      end

      nodes << token(klass,
        token(InToken, [
          token(LocalVariableToken, [
            name,
            type_token(value_type)
          ]),
          local_token(object_reg),
        ]),
        stmt_block(body))
    end
    alias :stmt_for_in      :stmt_for
    alias :stmt_for_each_in :stmt_for

    def stmt_break(opcode, nodes)
      label, = opcode.children
      nodes << token(BreakToken, [
        (token(LabelNameToken, label) if label)
      ])
    end

    def stmt_continue(opcode, nodes)
      label, = opcode.children
      nodes << token(ContinueToken, [
        (token(LabelNameToken, label) if label)
      ])
    end

    def stmt_throw(opcode, nodes)
      nodes << token(ThrowToken, exprs(opcode.children))
    end

    def stmt_return(opcode, nodes)
      nodes << token(ReturnToken, exprs(opcode.children))
    end
    alias :stmt_return_value :stmt_return
    alias :stmt_return_void  :stmt_return

    def stmt_try(opcode, nodes)
      body, *handlers = opcode.children

      nodes << token(TryToken, [
        stmt_block(body, continuation: true),
      ])

      handlers.each_with_index do |handler, index|
        block = within_meta_scope do
          stmt_block(handler.children.last, continuation: index < handlers.size - 1)
        end

        if handler.type == :catch
          type, variable, = handler.children

          if type
            filter_node = token(CatchFilterToken, [
              token(MultinameToken, variable.metadata[:origin]),
              token(MultinameToken, type.metadata[:origin])
            ])
          else
            filter_node = token(MultinameToken, variable.metadata[:origin])
          end

          nodes << token(CatchToken, filter_node, block)
        elsif handler.type == :finally
          nodes << token(FinallyToken, block)
        else
          raise "unknown handler type #{handler.type}"
        end
      end
    end

    def stmt_switch(opcode, nodes)
      condition, body = opcode.children

      nodes << token(SwitchToken,
        handle_expression(condition),
        stmt_block(body))
    end

    def stmt_default(opcode, nodes)
      nodes << token(CaseToken, nil)
    end

    def stmt_case(opcode, nodes)
      value, = opcode.children
      nodes << token(CaseToken, handle_expression(value))
    end

    def within_meta_scope
      @metascopes.push @scopes
      @scopes = []

      yield
    ensure
      @scopes = @metascopes.pop
    end

    KnownPushScopeMatcher = AST::Matcher.new do
      [:push_scope,
        either[
          [:get_local, capture(:get_local)],
          [:set_local, capture(:set_activation_local),
            [:new_activation]]
        ]
      ]
    end

    def stmt_push_scope(opcode, nodes)
      if @options[:global_code]
        @scopes.push opcode.children.first
      elsif captures = KnownPushScopeMatcher.match(opcode)
        if captures[:get_local] == 0
          @scopes << :this
        elsif !@activation_local.nil? &&
            captures[:get_local] == @activation_local
          @scopes << :activation
        elsif @catch_scopes.include? captures[:get_local]
          @scopes << @catch_scopes[captures[:get_local]]
        elsif captures[:set_activation_local]
          if @activation_local
            raise "more than one activation per function is not supported"
          end

          @scopes << :activation
          @activation_local = captures[:set_activation_local]
        else
          raise "abnormal matched pushscope in nonglobal code: #{captures.inspect}"
        end
      else
        raise "abnormal pushscope in nonglobal code"
      end
    end

    def stmt_pop_scope(opcode, nodes)
      if @options[:global_code]
        @scopes.pop
      elsif @scopes.any?
        @scopes.pop
      else
        raise "popscope with empty stack"
      end
    end

    def stmt_with(opcode, nodes)
      object, scope = opcode.children

      @scopes << :with
      nodes << token(WithToken,
          expr(object),
          stmt_block(scope))
    ensure
      @scopes.pop
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

    def local_token(index)
      if index < 0
        token(VariableNameToken, "sp#{-index}")
      elsif index == 0
        if @options[:static]
          token(VariableNameToken, @options[:instance].name.name)
        else
          token(ThisToken)
        end
      elsif index <= @method.param_count
        if @method.has_param_names?
          token(VariableNameToken, @method.param_names[index - 1])
        else
          token(VariableNameToken, "param#{index - 1}")
        end
      else
        token(VariableNameToken, "local#{index - @method.param_count - 1}")
      end
    end

    def expr_get_local(opcode)
      index, = opcode.children
      local_token(index)
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

        if scope.is_a? Hash
          # treat as an inline scope, probably from an eh
          if scope[captures[:index]]
            var = scope[captures[:index]]
            token(VariableNameToken, var.metadata[:origin].name)
          end
        elsif @closure_slots && scope == :activation
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

    def expr_set_var(var, value, type, declare, toplevel)
      if declare
        declaration =
          token(LocalVariableToken, [
            var,
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
          var,
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

      expr_set_var(local_token(index), value, type, !@locals.include?(index), toplevel)
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
          [:get_global_scope],
          [:push_scope,
            [:set_local, capture(:catch_local),
              [:new_catch, capture(:catch_id)]]]
        ],
        capture(:value)
      ]
    end

    ExceptionVariable = Matcher.new do
      [:exception_variable, capture(:variable)]
    end

    def expr_set_slot(opcode, toplevel=false)
      if captures = SetSlot.match(opcode)
        scope = @scopes[captures[:scope_pos] || 0]

        if captures[:catch_id]
          stmt = nil

          unless ExceptionVariable.match captures[:value], captures
            stmt = token(SupplementaryCommentToken,
              "Non-matching catch_id and catch id", [])
          end

          scope = {
            captures[:index] => captures[:variable]
          }

          @catch_scopes[captures[:catch_local]] = scope
          @scopes << scope

          throw :skip unless stmt
          stmt
        elsif @closure_slots && scope == :activation
          # treat as a local variable
          index, value = captures.values_at(:index, :value)
          slot = @closure_slots[index]

          type = type_token(slot.type.to_astlet) if slot.type
          expr = expr_set_var(token(VariableNameToken, slot.name.name),
                value, type,
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
      index, = opcode.children

      token(UnaryPostOperatorToken,
        local_token(index),
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
      lvar = local_token(index)

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

    PrePostIncDecSlot = Matcher.new do
      [any,
        capture(:index),
        either[
          [:get_global_scope],
          [:get_scope_object, capture(:scope_pos)]
        ]
      ]
    end

    def expr_prepost_incdec_slot(opcode)
      if captures = PrePostIncDecSlot.match(opcode)
        scope = @scopes[captures[:scope_pos] || 0]

        if @closure_slots && scope == :activation
          slot_trait = @closure_slots[captures[:index]]
          slot = token(VariableNameToken, slot_trait.name.name)

          if opcode.type == :post_increment_slot
            token(UnaryPostOperatorToken, slot, "++")
          elsif opcode.type == :post_decrement_slot
            token(UnaryPostOperatorToken, slot, "--")
          elsif opcode.type == :pre_increment_slot
            token(UnaryOperatorToken, slot, "++")
          elsif opcode.type == :pre_decrement_slot
            token(UnaryOperatorToken, slot, "--")
          end
        end
      end
    end
    alias :expr_post_increment_slot :expr_prepost_incdec_slot
    alias :expr_post_decrement_slot :expr_prepost_incdec_slot
    alias :expr_pre_increment_slot  :expr_prepost_incdec_slot
    alias :expr_pre_decrement_slot  :expr_prepost_incdec_slot

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
              [:get_scope_object, capture(:scope)],
              [:get_global_scope]
            ],
            capture(:multiname)
          ],
        ],
        capture_rest(:arguments)]
    end

    def pseudo_global_scope?(scope)
      [:this, :with].include?(@scopes[scope || 0])
    end

    def expr_get_lex(opcode)
      multiname, = opcode.children
      get_name(nil, multiname)
    end

    def expr_get_property(opcode)
      if captures = PropertyGlobal.match(opcode)
        return if !captures[:multiname] && !pseudo_global_scope?(captures[:scope])
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
        return if !captures[:multiname] && !pseudo_global_scope?(captures[:scope])
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
        return if !captures[:multiname] && !pseudo_global_scope?(captures[:scope])
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
            local_token(0),
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

    ## Alchemy opcodes

    ALCHEMY_BINARY_MAP = {
      :alchemy_store_int8    => AS3AlchemyStoreInt8,
      :alchemy_store_int16   => AS3AlchemyStoreInt16,
      :alchemy_store_int32   => AS3AlchemyStoreInt32,
      :alchemy_store_float32 => AS3AlchemyStoreFloat32,
      :alchemy_store_float64 => AS3AlchemyStoreFloat64
    }

    def expr_alchemy_binary_asm(node)
      value, address = node.children
      opcode = ALCHEMY_BINARY_MAP[node.type]

      token(CallToken, [
        token(AsmToken),
        token(ArgumentsToken, [
          token(AsmPushToken, [ expr(value) ]),
          token(AsmPushToken, [ expr(address) ]),
          token(SupplementaryCommentToken, node.type.to_s, [
            token(AsmOpToken, opcode)
          ])
        ])
      ])
    end

    alias :expr_alchemy_store_int8    :expr_alchemy_binary_asm
    alias :expr_alchemy_store_int16   :expr_alchemy_binary_asm
    alias :expr_alchemy_store_int32   :expr_alchemy_binary_asm
    alias :expr_alchemy_store_float32 :expr_alchemy_binary_asm
    alias :expr_alchemy_store_float64 :expr_alchemy_binary_asm

    ALCHEMY_UNARY_MAP = {
      :alchemy_load_int8    => AS3AlchemyLoadInt8,
      :alchemy_load_int16   => AS3AlchemyLoadInt16,
      :alchemy_load_int32   => AS3AlchemyLoadInt32,

      :alchemy_extend1      => AS3AlchemyExtend1,
      :alchemy_extend8      => AS3AlchemyExtend8,
      :alchemy_extend16     => AS3AlchemyExtend16
    }

    def expr_alchemy_unary_asm(node)
      value, = node.children
      opcode = ALCHEMY_UNARY_MAP[node.type]

      token(CallToken, [
        token(XAsmToken, [
          token(ImmediateTypenameToken, "uint")
        ]),
        token(ArgumentsToken, [
          token(AsmPushToken, [ expr(value) ]),
          token(SupplementaryCommentToken, node.type.to_s, [
            token(AsmOpToken, opcode)
          ])
        ])
      ])
    end

    alias :expr_alchemy_load_int8  :expr_alchemy_unary_asm
    alias :expr_alchemy_load_int16 :expr_alchemy_unary_asm
    alias :expr_alchemy_load_int32 :expr_alchemy_unary_asm
    alias :expr_alchemy_extend1    :expr_alchemy_unary_asm
    alias :expr_alchemy_extend8    :expr_alchemy_unary_asm
    alias :expr_alchemy_extend16   :expr_alchemy_unary_asm

    ALCHEMY_FLOAT_MAP = {
      :alchemy_load_float32 => AS3AlchemyLoadFloat32,
      :alchemy_load_float64 => AS3AlchemyLoadFloat64
    }

    def expr_alchemy_float_asm(node)
      value, = node.children
      opcode = ALCHEMY_FLOAT_MAP[node.type]

      token(CallToken, [
        token(XAsmToken, [
          token(ImmediateTypenameToken, "Number")
        ]),
        token(ArgumentsToken, [
          token(AsmPushToken, [ expr(value) ]),
          token(SupplementaryCommentToken, node.type.to_s, [
            token(AsmOpToken, opcode)
          ])
        ])
      ])
    end

    alias :expr_alchemy_load_float32 :expr_alchemy_float_asm
    alias :expr_alchemy_load_float64 :expr_alchemy_float_asm

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
        prefix = nil
        if [:QNameA, :MultinameA].include? origin.kind
          prefix = '@'
        end

        if subject
          token(AccessToken, [
            parenthesize(subject),
            token(PropertyNameToken, "#{prefix}#{origin.name}")
          ])
        else
          token(PropertyNameToken, "#{prefix}#{origin.name}")
        end
      when :MultinameL, :MultinameLA
        if subject
          token(IndexToken, [
            parenthesize(subject),
            expr(multiname.children.last)
          ])
        elsif @scopes[0] == :this
          token(IndexToken, [
            local_token(0),
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
      when :RTQNameL, :RTQNameLA
        token(RTNameToken, [
          parenthesize(expr(multiname.children.first)),
          parenthesize(expr(multiname.children.last))
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
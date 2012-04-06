module Furnace::AVM2
  class Decompiler
    include Furnace::AST
    include Furnace::AVM2::Tokens

    def initialize(body, options)
      @body, @options = body, options
    end

    def decompile
      @opcodes = @body.code_to_ast.children
      @state   = :prologue
      @nodes   = []

      while @opcodes.any?
        unless send :"on_#{@state}"
          @nodes << CommentToken.new(@body,
            "Decompiler stage #{@state} failed at\n" \
            "#{@error.inspect}\n",
          @options)
          break
        end
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
      when :integer
        token(ImmediateToken, *opcode.children)
      end
    end
    alias :expr_integer :expr_imm

    ## Call

    CallPropertyImplicit = Matcher.new do
      [:call_property,
        [:find_property_strict,
          [:m, any, capture(:name)]],
        [:m, any, backref(:name)],
        capture_rest(:arguments)]
    end

    def expr_call_property(opcode)
      if captures = CallPropertyImplicit.match(opcode)
        token(CallToken, [
          token(PropertyNameToken, captures[:name]),
          token(ArgumentsToken, exprs(captures[:arguments]))
        ])
      end
    end

    ## Return

    def expr_return(opcode)
      token(ReturnToken, exprs(opcode.children))
    end
    alias :expr_return_void :expr_return

    private

    def token(klass, *args)
      klass.new(@body, *args, @options)
    end
  end
end
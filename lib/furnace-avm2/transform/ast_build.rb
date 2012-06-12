module Furnace::AVM2
  module Transform
    # I'm not exactly proud of this code, but it works... for now. I really should
    # rework it if I want to expect it to work good.
    class ASTBuild
      CONDITIONAL_OPERATORS = [ :if_eq,  :if_false, :if_true,      :if_ge,        :if_gt,
                                :if_le,  :if_lt,    :if_ne,        :if_nge,       :if_ngt,
                                :if_nle, :if_nlt,   :if_strict_eq, :if_strict_ne, :if_true ]

      PURE_OPERATORS = [ :integer, :double, :string, :false, :true, :nan, :undefined, :null,
                         :find_property_strict ]

      PRE_POST_OPERATORS = [ :increment, :increment_i, :decrement, :decrement_i ]

      SHORT_ASSIGN_OPERATORS = [ :add, :add_i, :subtract, :subtract_i, :multiply, :multiply_i,
                                 :divide, :modulo,
                                 :set_local, :set_local_0, :set_local_1, :set_local_2, :set_local_3 ]

      def initialize(options)
        @validate = options[:validate] || false
        @verbose  = options[:verbose]  || false

        #@verbose = true
      end

      def consume(count)
        if count == 0
          []
        elsif count <= @stack.size
          @stack.slice!(-count..-1)
        else
          raise "cannot consume #{count}: stack underflow with #{@stack.size}"
        end
      end

      def produce(what)
        @stack.push what
      end

      def emit(node)
        if @verbose
          puts "emitted:"
          puts node.to_sexp(1)
        end

        @ast.children.push node
      end

      def unemit
        @ast.children.delete(-1)
      end

      def extend_complex_expr(valid_types, expected_depth=nil)
        expr, current = consume(2)

        if @validate
          if !valid_types.include?(expr.type)
            raise "invalid complex expr: #{expr.type} not in #{valid_types}"
          elsif expected_depth && expr.children.count != expected_depth
            raise "invalid complex expr: depth #{expr.children.count} != #{expected_depth}"
          end
        end

        expr.children << current
        produce(expr)
      end

      def finalize_complex_expr(opcode, worklist, valid_types, expected_depth=nil, wrap_to=nil)
        while worklist.last == opcode.offset
          extend_complex_expr(valid_types, expected_depth)

          if wrap_to
            node, *prepend = *wrap_to

            expr, = consume(1)
            expr = AST::Node.new(node, [*prepend, expr])
            produce(expr)
          end

          worklist.pop
        end
      end

      def expand_conditionals
        expressions = []

        while @stack.any? && CONDITIONAL_OPERATORS.include?(@stack.last.type)
          conditional, = consume(1)

          jump_node = AST::Node.new(:jump_if, [ true, conditional.metadata[:offset], conditional ])
          expressions.unshift jump_node
        end

        @ast.children.concat expressions
      end

      LocalIncDecInnerMatcher = AST::Matcher.new do
        [ either[*PRE_POST_OPERATORS],
          either[
            [:convert, any,
              [:get_local, any]],
            [:get_local, any],
          ]
        ]
      end

      def transform(code, body)
        @stack = []
        @ast   = AST::Node.new(:root)

        dup         = nil
        spurious    = 0

        in_shortcut = false
        shortjump   = []
        ternary     = []

        code.each do |opcode|
          if @verbose
            puts "================================"
            puts "stack: #{@stack.inspect}"
            puts "shortjump: #{shortjump.inspect} ternary: #{ternary.inspect}"
            puts "opcode: #{opcode.inspect}"
          end

          finalize_complex_expr(opcode, ternary, CONDITIONAL_OPERATORS, nil, [:ternary_if, false])
          finalize_complex_expr(opcode, shortjump, [ :and, :or ], 1)

          if dup == 1 && (opcode.is_a?(ABC::AS3CoerceB) ||
                  opcode.is_a?(ABC::AS3IfTrue) || opcode.is_a?(ABC::AS3IfFalse))
            in_shortcut  = true
            dup          = false
          end

          if in_shortcut
            if opcode.is_a?(ABC::AS3IfTrue)
              type = :or
            elsif opcode.is_a?(ABC::AS3IfFalse)
              type = :and
            elsif opcode.is_a?(ABC::AS3CoerceB)
              next
            elsif opcode.is_a?(ABC::AS3Pop)
              in_shortcut = false
              next
            elsif opcode.is_a?(ABC::AS3Jump) && opcode.body.jump_offset == 0
              # nop
              next
            else
              raise "invalid shortcut"
            end

            node = AST::Node.new(type, [], label: opcode.offset)
            node.children = consume(1)
            produce(node)

            shortjump.push opcode.target_offset
          elsif opcode.is_a?(ABC::AS3Swap)
            first, second = @stack.pop, @stack.pop
            @stack.push first, second
          elsif opcode.is_a?(ABC::AS3Dup)
            node = @stack.last

            if PURE_OPERATORS.include?(node.type) ||
                  (node.type == :get_local && node.children.first == 0)
              dup_node = node.dup
              dup_node.metadata[:label] = opcode.offset
              produce(dup_node)
            else
              dup ||= 0
              dup  += 1
            end
          elsif opcode.is_a?(ABC::AS3Jump)
            if opcode.body.jump_offset == 0
              node = AST::Node.new(:nop, [], label: opcode.offset)
              emit(node)
            elsif @stack.any? && !CONDITIONAL_OPERATORS.include?(@stack.last.type)
              extend_complex_expr(CONDITIONAL_OPERATORS)

              ternary.push opcode.target_offset
            else
              expand_conditionals()

              node = AST::Node.new(opcode.ast_type, opcode.parameters, label: opcode.offset)
              emit(node)
            end
          elsif opcode.is_a?(ABC::ControlTransferOpcode)
            node = AST::Node.new(opcode.ast_type, [], label: opcode.offset)
            node.metadata[:offset] = opcode.target_offset
            node.children = consume(opcode.consumes)
            produce(node)
          else
            node = AST::Node.new(opcode.ast_type, [], label: opcode.offset)

            if dup == 1
              top_opcode, = consume(1)
              found = true

              if PRE_POST_OPERATORS.include?(top_opcode.type)
                top_opcode.update(:"pre_#{top_opcode.type}")
              elsif PRE_POST_OPERATORS.include?(node.type)
                node.update(:"post_#{node.type}")
              elsif SHORT_ASSIGN_OPERATORS.include? top_opcode.type
                # just push it through
              else
                found = false
              end

              if found
                produce(AST::Node.new(:unemit))
                dup = false
              end

              produce(top_opcode)
            end

            if dup
              spurious += 1

              save_node = AST::Node.new(:set_local, [ -spurious, *consume(1) ])
              emit(save_node)

              (1 + dup).times do
                load_node = AST::Node.new(:get_local, [ -spurious ])
                produce(load_node)
              end

              dup = false
            end

            parameters = consume(opcode.consumes)
            if opcode.consumes_context
              context = opcode.context(consume(opcode.consumes_context))
            end

            node.children.concat context if context
            node.children.concat opcode.parameters
            node.children.concat parameters

            # All opcodes which produce 2 results--that is, dup and swap--
            # are already handled at the top.
            if opcode.produces == 0
              # This was a fallthrough assignment.
              if @stack.any? && @stack.last.type == :unemit
                consume(1) # dump unemit
                produce(node)
                next
              end

              expand_conditionals()

              # Spec does not require stack to be empty upon encountering return.
              # If there's something left, it should have been here.
              if opcode.is_a? ABC::FunctionReturnOpcode
                while @stack.any?
                  emit(*consume(1))
                end
              end

              emit(node)
            elsif opcode.produces == 1
              produce(node)
            end
          end
        end

        [ @ast.normalize_hierarchy!, body ]
      end
    end
  end
end
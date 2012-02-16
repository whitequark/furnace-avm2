module Furnace::AVM2
  module Transform
    class ASTBuild
      CONDITIONAL_OPERATORS = [ :if_eq,  :if_false, :if_true,      :if_ge,        :if_gt,
                                :if_le,  :if_lt,    :if_ne,        :if_nge,       :if_ngt,
                                :if_nle, :if_nlt,   :if_strict_eq, :if_strict_ne, :if_true ]

      CONST_OPERATORS = [ :integer, :double, :string, :false, :true, :nan, :undefined, :null ]

      def initialize(options)
        @validate = options[:validate] || false
        @verbose  = options[:verbose]  || false

        #@verbose = true
      end

      def transform(code, method)
        stack = []
        ast   = AST::Node.new(:root)

        dup         = nil
        spurious    = 0

        in_shortcut = false
        shortjump   = []
        ternary     = []

        consume = lambda do |count|
          if count == 0
            []
          elsif count <= stack.size
            stack.slice!(-count..-1)
          else
            raise "cannot consume #{count}: stack underflow with #{stack.size}"
          end
        end

        produce = lambda do |what|
          stack.push what
        end

        emit = lambda do |node|
          if @verbose
            puts "emitted:"
            puts node.to_sexp(1)
          end

          ast.children.push node
        end

        extend_complex_expr = lambda do |valid_types, expected_depth=nil|
          expr, current = consume.(2)

          if @validate
            if !valid_types.include?(expr.type)
              raise "invalid complex expr: #{expr.type} not in #{valid_types}"
            elsif expected_depth && expr.children.count != expected_depth
              raise "invalid complex expr: depth #{expr.children.count} != #{expected_depth}"
            end
          end

          expr.children << current
          produce.(expr)
        end

        finalize_complex_expr = lambda do |opcode, worklist, valid_types, expected_depth=nil|
          while worklist.last == opcode.offset
            extend_complex_expr.(valid_types, expected_depth)
            worklist.pop
          end
        end

        expand_conditionals = lambda do
          while stack.any? && CONDITIONAL_OPERATORS.include?(stack.last.type)
            conditional, = consume.(1)

            jump_node = AST::Node.new(:jump_if, [ true, conditional.metadata[:offset], conditional ])
            emit.(jump_node)
          end
        end

        code.each do |opcode|
          if @verbose
            puts "================================"
            puts "stack: #{stack.inspect}"
            puts "shortjump: #{shortjump.inspect} ternary: #{ternary.inspect}"
            puts "opcode: #{opcode.inspect}"
          end

          finalize_complex_expr.(opcode, shortjump, [ :and, :or ], 1)
          finalize_complex_expr.(opcode, ternary, CONDITIONAL_OPERATORS)

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
            node.children = consume.(1)
            produce.(node)

            shortjump.push opcode.target_offset
          elsif opcode.is_a?(ABC::AS3Swap)
            first, second = stack.pop, stack.pop
            stack.push first, second
          elsif opcode.is_a?(ABC::AS3Dup)
            node = stack.last

            if CONST_OPERATORS.include? node.type
              dup_node = node.dup
              dup_node.metadata[:label] = opcode.offset
              produce.(dup_node)
            else
              dup ||= 0
              dup  += 1
            end
          elsif opcode.is_a?(ABC::AS3Jump)
            if opcode.body.jump_offset == 0
              node = AST::Node.new(:jump_target, [], label: opcode.offset)
              emit.(node)
            elsif stack.any? && !CONDITIONAL_OPERATORS.include?(stack.last.type)
              extend_complex_expr.(CONDITIONAL_OPERATORS)

              ternary.push opcode.target_offset
            else
              expand_conditionals.()

              node = AST::Node.new(opcode.ast_type, opcode.parameters, label: opcode.offset)
              emit.(node)
            end
          elsif opcode.is_a?(ABC::ControlTransferOpcode)
            node = AST::Node.new(opcode.ast_type, [], label: opcode.offset)
            node.metadata[:offset] = opcode.target_offset
            node.children = consume.(opcode.consumes)
            produce.(node)
          elsif opcode.is_a?(ABC::AS3Kill)
            # Ignore. SSA will handle that.
          else
            if dup
              spurious += 1

              save_node = AST::Node.new(:set_spurious, [ spurious, *consume.(1) ])
              emit.(save_node)

              (1 + dup).times do
                load_node = AST::Node.new(:get_spurious, [ spurious ])
                produce.(load_node)
              end

              dup = false
            end

            node = AST::Node.new(opcode.ast_type, [], label: opcode.offset)

            parameters = consume.(opcode.consumes)
            if opcode.consumes_context
              context = opcode.context(consume.(opcode.consumes_context))
            end

            node.children.concat context if context
            node.children.concat opcode.parameters
            node.children.concat parameters

            # All opcodes which produce 2 results--that is, dup and swap--
            # are already handled at the top.
            if opcode.produces == 0
              expand_conditionals.()
              emit.(node)
            elsif opcode.produces == 1
              produce.(node)
            end
          end
        end

        if @validate
          extracted_opcodes = []
          extract = lambda do |tree|
            extracted_opcodes.push tree.metadata[:label]
            tree.select { |c| c.is_a? Node }.each { |c| extract.(c) }
          end
        end

        [ ast.normalize_hierarchy!, method ]
      end
    end
  end
end
module Furnace::AVM2
  module Transform
    class CFGBuild
      def transform(ast, body)
        @jumps      = Set.new
        @exceptions = {}

        @cfg = CFG::Graph.new

        body.exceptions.each_with_index do |exc, index|
          unless exc_block = @exceptions[exc.range]
            exc_block = CFG::Node.new(@cfg, "exc_#{index}")

            dispatch_node = AST::Node.new(:exception_dispatch)
            exc_block.insns << dispatch_node
            exc_block.cti = dispatch_node

            @exceptions[exc.range] = exc_block
          end

          exc_block.target_labels << exc.target_offset
          exc_block.cti.children <<
              AST::Node.new(:catch,
                [ exc.exception.to_astlet,
                  exc.variable.to_astlet,
                  exc.target_offset ])
        end

        @pending_label = nil
        @pending_exc_block = nil
        @pending_exc_range = nil
        @pending_queue = []

        ast.children.each_with_index do |node, index|
          unless @pending_label
            @pending_label = node.metadata[:label]

            exception_block_for(@pending_label) do |block, range|
              @pending_exc_block = block
              @pending_exc_range = range
            end
          end

          @pending_queue << node if ![:nop, :jump].include? node.type

          next_node  = ast.children[index + 1]
          next_label = next_node.metadata[:label] if next_node

          case node.type
          when :label
            node.update :nop

          when :return_value, :return_void
            cutoff(nil, [nil])

          when :jump
            @jumps.add(node.children[0])
            cutoff(nil, [ node.children.delete_at(0) ])

          when :jump_if
            @jumps.add(node.children[1])
            cutoff(node, [ node.children.delete_at(1), next_label ])

          when :lookup_switch
            jumps_to = [ node.children[0] ] + node.children[1]
            @jumps.merge(jumps_to)
            cutoff(node, jumps_to)

          else
            *, next_exception_block = exception_block_for(next_label)

            if @jumps.include?(next_label) || next_node.type == :label
              cutoff(nil, [next_label])
            elsif @pending_exc_block != next_exception_block
              cutoff(nil, [next_label])
            end
          end
        end

        exit_node = CFG::Node.new(@cfg)
        @cfg.nodes.add exit_node
        @cfg.exit = exit_node

        @exceptions.values.each do |exc_node|
          @cfg.nodes.add exc_node
        end

        @cfg.eliminate_unreachable!
        @cfg.merge_redundant!

        @cfg
      end

      private

      def cutoff(cti, targets)
        node = CFG::Node.new(@cfg, @pending_label, @pending_queue, cti, targets)
        if @pending_exc_block
          node.exception_label = @pending_exc_block.label
        end

        if @cfg.nodes.empty?
          @cfg.entry = node
        end

        @cfg.nodes.add node

        @pending_label = nil
        @pending_exc_block = nil
        @pending_exc_range = nil
        @pending_queue = []
      end

      def exception_block_for(label)
        return nil unless label

        @exceptions.find do |range, block|
          if range.include? label
            yield block, range if block_given?
            true
          end
        end
      end
    end
  end
end
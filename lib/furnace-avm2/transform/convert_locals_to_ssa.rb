module Furnace::AVM2
  module Transform
    class ConvertLocalsToSSA
      include SubgraphOperations

      class GetLocalUpdater
        include Furnace::AST::Visitor

        attr_reader :get_locals

        def initialize(metadata, variable_map)
          @metadata, @variable_map = metadata, variable_map
        end

        def update(ast)
          @get_locals = Set[]
          @upper      = ast

          visit ast
        end

        def on_get_local(node)
          index, = node.children

          @get_locals.add index

          ids = (@variable_map[index] & @metadata.live).to_a
          node.update(:r, ids)
          @metadata.add_get ids, @upper, node
        end
      end

      def initialize(options={})
        @method = options[:method]
      end

      def transform(cfg)
        next_id      = 0
        variable_map = Hash.new { |h, k| h[k] = Set[] }

        # Prepend implicit `this' and params.
        implicit = 0.upto(1 + @method.param_count).map do |local|
          case local
          when 0
            inner_node = AST::Node.new(:this)
          else
            inner_node = AST::Node.new(:param, [ local - 1 ])
          end

          AST::Node.new(:set_local, [
              local, inner_node
            ], {
              read_barrier:  Set[],
              write_barrier: Set[],
            })
        end

        cfg.entry.insns.insert(0, *implicit)

        # Convert (set-local) to (s).
        cfg.nodes.each do |block|
          set_locals = []

          block.insns.map! do |node|
            if node.type == :set_local
              index, value = node.children
              node.metadata[:write_barrier].delete :"local_#{index}"

              s_index  = next_id
              next_id -= 1

              s_node = AST::Node.new(:s,
                [ s_index, value ],
                node.metadata)
              block.metadata.add_set s_index, s_node

              block.metadata.gets_upper.each do |get, upper|
                if upper == node
                  block.metadata.gets_upper[get] = s_node
                end
              end

              set_locals << s_index
              variable_map[index].add s_index

              s_node
            else
              node
            end
          end

          if set_locals.any?
            walk_nodes cfg, block do |child_block|
              child_block.metadata.live.merge set_locals
            end
          end
        end

        # Convert (get-local) to (r).
        cfg.nodes.each do |block|
          updater = GetLocalUpdater.new(block.metadata, variable_map)

          block.insns.each do |node|
            updater.update node

            updater.get_locals.each do |index|
              node.metadata[:read_barrier].delete :"local_#{index}"
            end
          end
        end

        # Limit the scope of variables to minimally possible.
        worklist = cfg.nodes.to_set
        while worklist.any?
          block = worklist.first
          worklist.delete block

          alive_in_targets = block.targets.
                map { |t| t.metadata.live }.
                reduce(Set[], :|)

          old_live = block.metadata.live
          block.metadata.live &=
                alive_in_targets |
                block.metadata.sets |
                block.metadata.gets
          #p "BLOCK", block.label
          #p old_live, block.metadata.live, alive_in_targets | block.metadata.sets

          if old_live != block.metadata.live
            block.sources.each do |source|
              worklist.add source
            end
          end
        end

        cfg
      end
    end
  end
end
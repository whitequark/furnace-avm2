module Furnace::AVM2
  module Transform
    class RefineLocalVariableBarriers
      class Visitor
        include Furnace::AST::StrictVisitor

        def on_s(node)
          index, value = node.children
          refine value, node
        end

        def on_set_local(node)
          refine node, node
        end

        def refine(node, root)
          case node.type
          when :get_local
            reg, = node.children
            root.metadata[:read_barrier].delete :local
            root.metadata[:read_barrier].add :"local_#{reg}"

          when :set_local
            reg, = node.children
            root.metadata[:write_barrier].delete :local
            root.metadata[:write_barrier].add :"local_#{reg}"

          when :has_next2
            object_reg, index_reg, = node.children
            root.metadata[:write_barrier].delete :local
            root.metadata[:write_barrier].add :"local_#{object_reg}"
            root.metadata[:write_barrier].add :"local_#{index_reg}"
          end
        end
      end

      def transform(cfg, info)
        visitor = Visitor.new

        cfg.nodes.each do |node|
          visitor.visit_all node.insns
        end

        [ cfg, info ]
      end
    end
  end
end

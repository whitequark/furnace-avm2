module Furnace::AVM2
  module Transform
    class PartialEvaluation
      def transform(cfg)
        changed = false

        evaluator = Evaluator.new

        cfg.nodes.each do |block|
          if block.cti && block.cti.type == :branch_if
            compare_to, expr = block.cti.children
            if folded = evaluator.fold(expr)
              folded = evaluator.to_boolean(folded)
              value = evaluator.value folded

              if value ^ compare_to
                block.target_labels = [ block.target_labels[1] ]
              else
                block.target_labels = [ block.target_labels[0] ]
              end

              block.insns.delete block.cti
              block.cti = nil

              changed = true
            end
          end
        end

        cfg if changed
      end
    end
  end
end
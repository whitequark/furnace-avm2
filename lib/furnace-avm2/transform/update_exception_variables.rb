module Furnace::AVM2
  module Transform
    class UpdateExceptionVariables
      def transform(cfg)
        cfg.nodes.each do |block|
          if block.metadata[:exception]
            block.cti.children.each do |catch|
              error, variable, target = catch.children
              target_block = cfg.find_node target
              target_block.metadata.gets_map[block.label].each do |node|
                node.update(:exception_variable, [ variable ])
              end
            end
          end
        end

        cfg
      end
    end
  end
end
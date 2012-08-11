module Furnace::AVM2
  module Transform
    class LivenessAnalysis
      # Avoid creating too much literals.
      EMPTY_SET = Set[]

      def transform(cfg)
        # Clear old data
        cfg.nodes.each do |block|
          block.metadata.live = nil
          block.metadata.dead = nil
        end

        # Search from the entry node, mark live variables
        worklist = Set[ cfg.entry ]
        while worklist.any?
          block = worklist.first
          worklist.delete block

          old_live = block.metadata.live
          block.metadata.live =
            block.metadata.sets +
            block.sources.map { |s| s.metadata.live || EMPTY_SET }.
                          reduce(EMPTY_SET, :|)

          if block.metadata.live != old_live
            [ *block.targets, block.exception ].compact.
                  each do |target|
              worklist.add target
            end
          end
        end

        cfg.exit.metadata.dead = cfg.exit.metadata.live

        # Search from the exit node, unmark dead variables
        worklist = Set[ cfg.exit ]
        while worklist.any?
          block = worklist.first
          worklist.delete block

          unless block == cfg.exit
            old_dead = block.metadata.dead
            block.metadata.dead =
              block.targets.map { |s| s.metadata.dead || EMPTY_SET }.
                            reduce(:&) -
              block.metadata.gets
          end

          if block.metadata.dead != old_dead
            block.sources.each do |source|
              worklist.add source
            end
          end
        end

        # Subtract dead from live
        cfg.nodes.each do |block|
          block.metadata.live.subtract block.metadata.dead
          block.metadata.dead = nil
        end

        # This transform does not change CFG in any way,
        # it just rebuilds the metadata.
        nil
      end
    end
  end
end
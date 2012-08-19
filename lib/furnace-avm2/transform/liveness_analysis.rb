module Furnace::AVM2
  module Transform
    class LivenessAnalysis
      # Avoid creating too much literals.
      EMPTY_SET = Set[]

      def transform(cfg)
        dom   = cfg.dominators
        loops = cfg.identify_loops

        # Clear old data
        cfg.nodes.each do |block|
          block.metadata.live = nil
          block.metadata.dead = nil
        end

        dead_ends = Set[ cfg.exit ]

        # Search from the entry node, mark live variables
        worklist = Set[ cfg.entry ]
        while worklist.any?
          block = worklist.first
          worklist.delete block

          if block.cti && block.cti.type == :throw
            dead_ends.add block
          elsif loops.include? block
            back_edged, sources = block.sources.partition do |source|
              dom[source].include? block
            end
            dead_ends.merge back_edged
          else
            sources = block.sources
          end

          old_live = block.metadata.live
          block.metadata.live =
            block.metadata.sets +
            sources.map { |s| s.metadata.live || EMPTY_SET }.
                          reduce(EMPTY_SET, :|)

          if block.metadata.live != old_live
            [ *block.targets, block.exception ].compact.
                  each do |target|
              worklist.add target
            end
          end
        end

        # Search from the exit node, unmark dead variables
        worklist = dead_ends.dup
        while worklist.any?
          block = worklist.first
          worklist.delete block

          old_dead = block.metadata.dead

          if dead_ends.include? block
            block.metadata.dead =
              block.metadata.live -
              block.metadata.gets
          else
            block.metadata.dead =
              block.targets.map { |s| s.metadata.dead || EMPTY_SET }.
                      reduce(:&) -
              block.metadata.gets
          end

          if block.metadata.dead != old_dead
            [ *block.sources, *block.exception_sources ].each do |source|
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
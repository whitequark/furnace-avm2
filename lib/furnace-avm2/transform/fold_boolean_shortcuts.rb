module Furnace::AVM2
  module Transform
    class FoldBooleanShortcuts
      include PhiNodeReduction

      ValidCondition = Furnace::AST::Matcher.new do
        [:branch_if, any,
          either[
            [:coerce, :boolean,
              backref(:get)],
            backref(:get)
          ]
        ]
      end

      def transform(cfg)
        changed = false

        cfg.nodes.each do |block|
          next if block.metadata[:exception]

          # Find a phi node.

          gets = block.metadata.gets_map.values.
                          map(&:to_a).flatten.uniq

          gets.select do |get|
            get.children.count > 1
          end.each do |phi|
            # Find two sources, one of which is a source of another one,
            # and the latter should only have one instruction in it.

            # id => source
            sources = Hash[
              phi.children.map do |id|
                [ id, block.sources.find { |source| source.metadata.sets.include?(id) } ]
              end.select do |id, source|
                source
              end
            ]

            top = top_id = bottom = bottom_id = nil

            (top_id, top) = sources.find do |top_id, top_source|
              (bottom_id, bottom) = sources.find do |bottom_id, bottom_source|
                next if top_source == bottom_source

                bottom_source.sources.first == top_source &&
                  bottom_source.insns.count == 1
              end
            end

            unless top
              next
            end

            # Run sanity checks: each source should only set its
            # respective id; their shared source should have branch_if cti.

            unless bottom.metadata.sets.count == 1 &&
                      bottom.insns.count == 1 &&
                      top.cti.type == :branch_if &&
                      top.metadata.gets_map[top_id].count == 1
              next
            end

            compare_to, top_value = top.cti.children
            top_get = top.metadata.gets_map[top_id].first

            unless ValidCondition.match top.cti,
                   { get: top_get }
              next
            end

            if compare_to
              operation = :or
            else
              operation = :and
            end

            top_get = top_get.dup

            bottom_set = bottom.metadata.set_map[bottom_id]
            *, bottom_value = bottom_set.children

            bottom_set.update(:s, [
              bottom_id,
              AST::Node.new(operation, [
                top_get,
                bottom_value
              ])
            ])

            top.metadata.remove_get top_id

            top.insns.delete top.cti
            top.cti = nil
            top.target_labels.delete_at top.targets.index(block)

            bottom.metadata.add_get [top_id], bottom_set, top_get

            reduce_phi_nodes(cfg, block, top_id, bottom_id)

            changed = true
          end
        end

        cfg if changed
      end
    end
  end
end
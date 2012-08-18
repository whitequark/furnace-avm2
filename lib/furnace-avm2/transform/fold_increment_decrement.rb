module Furnace::AVM2
  module Transform
    class FoldIncrementDecrement
      OPERATIONS = [:increment, :decrement]

      PossiblyConvertingGet = AST::Matcher.new do
        either[
          [:r, backref(:id)],
          [:convert, :integer,
            [:r, backref(:id)]]
        ]
      end

      PostXrementSet = AST::Matcher.new do
        [:s, capture(:id),
          either[
            [:get_local, capture(:local)],
            [:get_slot,  capture(:slot), capture(:scope)]
          ]
        ]
      end

      PostXrementGet = AST::Matcher.new do
        either[
          [:set_local, backref(:local),
            [capture(:operation),
              capture(:get)]],
          [:set_slot, backref(:slot), backref(:scope),
            [capture(:operation),
              capture(:get)]]
        ]
      end

      PreXrementSet = AST::Matcher.new do
        [:s, capture(:id),
          [capture(:operation),
            either[
              [:get_local, capture(:local)],
              [:get_slot,  capture(:slot), capture(:scope)]
            ]
          ]
        ]
      end

      PreXrementGet = AST::Matcher.new do
        either[
          [:set_local, backref(:local),
            capture(:get)],
          [:set_slot, backref(:slot), backref(:scope),
            capture(:get)],
        ]
      end

      def transform(cfg)
        changed = false

        cfg.nodes.each do |block|
          metadata = block.metadata

          metadata.sets.each do |id|
            set = metadata.set_map[id]

            sorted_gets = block.metadata.gets_map[id].map do |node|
              [ node, block.metadata.gets_upper[node] ]
            end.sort_by do |node, upper|
              block.insns.index(upper)
            end

            next if sorted_gets.none?

            get, get_upper = sorted_gets.first

            # This transformation performs the following folding (where
            # Xrement stands for increment or decrement):

            # 1. Post-Xrement local:
            #     (s N (get-local L))
            #     (set-local L (Xrement (r N)))
            #   is folded to:
            #     (s N (post-Xrement-local L))
            #
            #   Post-Xrement slot:
            #     (s N (get-slot P S))
            #     (set-slot P S (Xrement (r N)))
            #   is folded to:
            #     (s N (post-Xrement-slot P S))
            #
            # 2. Pre-Xrement local:
            #     (s N (Xrement (get-local L)))
            #     (set-local L (r N))
            #   is folded to:
            #     (s N (pre-Xrement-local L))
            #
            #   Pre-Xrement slot:
            #     (s N (Xrement (get-slot P S)))
            #     (set-slot P S (r N))
            #   is folded to:
            #     (s N (pre-Xrement-slot P S))

            type = nil

            if captures = PostXrementSet.match(set)
              if PostXrementGet.match(get_upper, captures) &&
                    OPERATIONS.include?(captures[:operation]) &&
                    PossiblyConvertingGet.match(captures[:get], captures)
                type = "post"
              end
            elsif captures = PreXrementSet.match(set)
              if PreXrementGet.match(get_upper, captures) &&
                    OPERATIONS.include?(captures[:operation]) &&
                    PossiblyConvertingGet.match(captures[:get], captures)
                type = "pre"
              end
            end

            next if type.nil?

            block.insns.delete get_upper

            metadata.gets_map[id].delete get
            metadata.gets_upper.delete get
            if metadata.gets_map[id].empty?
              metadata.gets.delete id
            end

            if captures[:local]
              updater = AST::Node.new(
                :"#{type}_#{captures[:operation]}_local",
                [ captures[:local] ]
              )
              set.metadata[:write_barrier].add :"local_#{captures[:local]}"
            else
              updater = AST::Node.new(
                :"#{type}_#{captures[:operation]}_slot",
                [ captures[:slot], captures[:scope] ]
              )
              set.metadata[:write_barrier].add :memory
            end

            set.update(:s, [ id, updater ])

            changed = true
          end
        end

        cfg if changed
      end
    end
  end
end
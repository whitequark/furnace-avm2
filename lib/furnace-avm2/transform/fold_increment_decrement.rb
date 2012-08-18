module Furnace::AVM2
  module Transform
    class FoldIncrementDecrement
      OPERATIONS = [:increment, :decrement]

      def self.possibly_converting(type)
        AST::Matcher.new do
          either[
            [:convert, either[:integer, :double],
              capture(type)],
            capture(type)
          ]
        end
      end

      ConvOpInner = possibly_converting(:op_inner)
      ConvOpOuter = possibly_converting(:op_outer)
      ConvSingle  = possibly_converting(:single)

      GetValue = AST::Matcher.new do
        either[
          [:get_local, capture(:local)],
          [:get_slot,  capture(:slot), capture(:scope)]
        ]
      end

      UpdateValue = AST::Matcher.new do
        [capture(:operation), capture(:update)]
      end

      SetValue = AST::Matcher.new do
        either[
          [:set_local, capture(:local),
            capture(:value)],
          [:set_slot,  capture(:slot), capture(:scope),
            capture(:value)]
        ]
      end

      def transform(cfg)
        changed = false

        cfg.nodes.each do |block|
          metadata = block.metadata

          metadata.sets.each do |id|
            set = metadata.set_map[id]
            _, set_value = set.children

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

            # This is pretty arcane.
            if (captures = ConvSingle.match(set_value)) &&
                  GetValue.match(captures[:single], captures) &&
                  SetValue.match(get_upper, captures) &&
                  ConvOpOuter.match(captures[:value], captures) &&
                  UpdateValue.match(captures[:op_outer], captures) &&
                  OPERATIONS.include?(captures[:operation]) &&
                  ConvOpInner.match(captures[:update], captures) &&
                  captures[:op_inner] == get
              type = "post"
            elsif (captures = ConvOpOuter.match(set_value)) &&
                  UpdateValue.match(captures[:op_outer], captures) &&
                  OPERATIONS.include?(captures[:operation]) &&
                  ConvOpInner.match(captures[:update], captures) &&
                  GetValue.match(captures[:op_inner], captures) &&
                  SetValue.match(get_upper, captures) &&
                  ConvSingle.match(captures[:value], captures) &&
                  captures[:single] == get
              type = "pre"
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
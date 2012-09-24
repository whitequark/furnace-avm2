module Furnace::AVM2
  module Transform
    class MetadataCheck
      include AST::Visitor

      def on_s(node)
        id, value = node.children
        @set_map[id] = node
        @sets.add id
      end

      def on_r(node)
        ids = node.children
        ids.each do |id|
          @gets.add id
          @gets_map[id] << node
          @gets_upper[node] = @upper
        end
      end

      def initialize(options={})
        @idempotent = options[:idempotent] || false
        @after      = options[:after]
      end

      def transform(cfg)
        cfg.nodes.each do |block|
          @sets = Set[]
          @gets = Set[]
          @set_map    = {}
          @gets_map   = Hash.new { |h, k| h[k] = Set[] }
          @gets_upper = {}

          block.insns.each do |node|
            @upper = node
            visit node
          end

          metadata = block.metadata

          metadata.gets_map.each do |id,|
            # make automatically created sets to be the same in both hashes
            @gets_map[id]
          end

          block = "block #{block.label}"
          block << " after #{@after}" if @after

          if @gets != metadata.gets
            raise "#{block}: gets mismatch: diff: actual #{(@gets - metadata.gets).inspect}, stored #{(metadata.gets - @gets).inspect}"
          end

          if @sets != metadata.sets
            raise "#{block}: sets mismatch: diff: actual #{(@sets - metadata.sets).inspect}, stored #{(metadata.sets - @sets).inspect}"
          end

          if @set_map != metadata.set_map
            raise "#{block}: set map mismatch: actual #{@set_map.pretty_inspect}, stored #{metadata.set_map.pretty_inspect}"
          end

          if @gets_map != metadata.gets_map
            raise "#{block}: gets map mismatch: actual #{@gets_map.pretty_inspect}, stored #{metadata.gets_map.pretty_inspect}"
          end

          if @gets_upper != metadata.gets_upper
            raise "#{block}: gets upper mismatch: actual #{@gets_upper.pretty_inspect}, stored #{metadata.gets_upper.pretty_inspect}"
          end
        end

        if @idempotent
          cfg
        else
          nil
        end
      end
    end
  end
end
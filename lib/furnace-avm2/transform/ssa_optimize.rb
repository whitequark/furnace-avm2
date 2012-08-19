module Furnace::AVM2
  module Transform
    class SSAOptimize
      def initialize(options={})
        @idempotent = options[:idempotent]
        @idempotent = false if @idempotent.nil?
      end

      def transform(cfg)
        changed = false

        cfg.eliminate_unreachable! do |dead|
          changed = true
        end

        cfg.merge_redundant! do |alive, dead|
          alive.metadata.merge! dead.metadata
          changed = true
        end

        if changed || @idempotent
          cfg
        end
      end
    end
  end
end
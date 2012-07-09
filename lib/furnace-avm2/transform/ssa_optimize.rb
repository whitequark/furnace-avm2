module Furnace::AVM2
  module Transform
    class SSAOptimize
      def transform(cfg)
        cfg.eliminate_unreachable!

        cfg.merge_redundant! do |alive, dead|
          alive.metadata.merge! dead.metadata
        end

        cfg
      end
    end
  end
end
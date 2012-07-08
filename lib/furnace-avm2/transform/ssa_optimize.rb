module Furnace::AVM2
  module Transform
    class SSAOptimize
      def transform(cfg, info)
        cfg.eliminate_unreachable!

        cfg.merge_redundant! do |alive, dead|
          alive_info, dead_info = info.values_at(alive, dead)

          alive_info[:sets].merge dead_info[:sets]
          alive_info[:gets].merge dead_info[:gets]

          alive_info[:set_map].merge! dead_info[:set_map]
          alive_info[:gets_map].merge!(dead_info[:gets_map]) { |h, ak, dk| ak + dk }
          alive_info[:gets_upper].merge! dead_info[:gets_upper]

          dead.insns.delete dead.insns.find { |n| n.type == :_info }
        end

        [ cfg, info ]
      end
    end
  end
end
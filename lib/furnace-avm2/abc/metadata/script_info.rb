module Furnace::AVM2::ABC
  class ScriptInfo < Record
    include InitializerBody

    root_ref     :initializer,  :method

    abc_array_of :trait, :nested, :class => TraitInfo

    def collect_ns
      ns = []
      ns += initializer.collect_ns if initializer
      traits.each { |trait| ns += trait.collect_ns }
      ns
    end

    def decompile(options={})
      non_inits = traits.reject { |trait| trait.kind == :Class }
      if non_inits.any?
        Furnace::AVM2::Tokens::PackageToken.new(self,
              options.merge(ns: collect_ns,
                  package_type: :script,
                  package_name: non_inits[0].name))
      end
    end
  end
end

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
      Furnace::AVM2::Tokens::PackageToken.new(self,
            options.merge(ns: collect_ns,
                package_type: :script,
                package_name: non_init_traits[0].name))
    end

    def any_code?
      non_init_traits.any?
    end

    def non_init_traits
      traits.reject { |trait| trait.kind == :Class }
    end
  end
end

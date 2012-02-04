# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "furnace-avm2"
  s.version     = "0.0.3"
  s.authors     = ["Peter Zotov"]
  s.email       = ["whitequark@whitequark.org"]
  s.homepage    = "http://github.com/whitequark/furnace-avm2"
  s.summary     = %q{AVM2 analysis framework based on Furnace}
  s.description = %q{furnace-avm2 allows one to load, modify and write back} <<
                  %q{Flash ActionScript3 bytecode. It can also decompile it.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "furnace", '>= 0.0.4'
  s.add_runtime_dependency "trollop"
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "furnace-avm2/version"

Gem::Specification.new do |s|
  s.name        = "furnace-avm2"
  s.version     = Furnace::AVM2::VERSION
  s.authors     = ["Peter Zotov"]
  s.email       = ["whitequark@whitequark.org"]
  s.homepage    = "http://github.com/whitequark/furnace-avm2"
  s.summary     = %q{AVM2 analysis framework based on Furnace}
  s.description = %q{furnace-avm2 allows one to load, modify and write back } <<
                  %q{Flash ActionScript3 bytecode. It can also decompile it.}

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 1.9.1'

  s.add_runtime_dependency "furnace", '= 0.2.5'
  s.add_runtime_dependency "trollop"
end

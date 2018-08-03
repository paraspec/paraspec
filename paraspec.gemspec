# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "paraspec"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Oleg Pudeyev"]
  s.email       = "oleg@olegp.name"
  s.homepage    = "https://github.com/paraspec/paraspec"
  s.summary     = "paraspec-0.0.1"
  s.description = "Parallel RSpec runner"

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += %w[README.md LICENSE]
  s.test_files       = []
  s.bindir           = 'bin'
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency "rspec-core", "~> 3.7.1"
  s.add_runtime_dependency "childprocess", "~> 0.9.0"
  s.add_runtime_dependency "hashie", "~> 3.5.7"
  s.add_runtime_dependency "msgpack", "~> 1.2.4"
end

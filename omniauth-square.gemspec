# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-square/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-square"
  s.version     = Omniauth::Square::VERSION
  s.authors     = ["Daniel Archer", "Jennifer Aprahamian", "Adam Bouck", "Ray Zane"]
  s.email       = ["me@dja.io", "j.aprahamian@gmail.com", "adam.j.bouck@gmail.com", "raymondzane@gmail.com"]
  s.homepage    = "https://github.com/dja/omniauth-square"
  s.summary     = %q{Square OAuth strategy for OmniAuth}
  s.description = %q{Square OAuth strategy for OmniAuth}
  s.license           = "MIT"

  s.rubyforge_project = "omniauth-square"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth-oauth2', '>= 1.1.1', '< 2.0.0'
  s.add_development_dependency 'rspec', '~> 2.7'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'webmock'
end

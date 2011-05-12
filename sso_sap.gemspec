# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sso_sap/version"

Gem::Specification.new do |s|
  s.name        = "sso_sap"
  s.version     = SsoSap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Krollpfeifer"]
  s.email       = ["simon.krollpfeifer@peritor.com"]
  s.homepage    = ""
  s.summary     = %q{ Gem for SSO with the LDAP backend }
  s.description = %q{ Use this gem to handle user login while within the SAP network }

	s.add_development_dependency "rspec"
	s.add_development_dependency "mocha"
	s.add_development_dependency "rails"		
	s.add_dependency "rails"
	s.add_dependency "rack"
	
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

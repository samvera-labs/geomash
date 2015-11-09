$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "geomash/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "geomash"
  s.version     = Geomash::VERSION
  s.authors     = ["Boston Public Library"]
  s.email       = ["sanderson@bpl.org"]
  s.homepage    = "http://www.bpl.org"
  s.summary     = "Parse string for potential geographic matches and return that data along with the TGN ID and Geonames ID."
  s.description = "Parse string for potential geographic matches and return that data along with the TGN ID and Geonames ID."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activesupport"
  s.add_dependency "countries", '0.11.5' #FIXME: Seems broken in later versions?
  s.add_dependency "geocoder"
  s.add_dependency 'unidecoder'
  s.add_dependency 'typhoeus'
  s.add_dependency 'nokogiri'
  s.add_dependency 'htmlentities'
  s.add_dependency 'sparql'
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails"
end

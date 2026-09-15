require_relative "lib/foothold/version"

Gem::Specification.new do |spec|
  spec.name        = "foothold"
  spec.version     = Foothold::VERSION
  spec.authors     = [ "Scott Harvey" ]
  spec.email       = [ "scott@scottharvey.co" ]
  spec.homepage    = "https://github.com/scottharvey/foothold"
  spec.summary     = "Operator-only watch on one product's presence on the web."
  spec.description = "Foothold collects search readings, referrers and mentions for a product on a schedule, joins them with what visitors did next, and turns the result into a short queue of leads and a weekly digest."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.required_ruby_version = ">= 3.2"
  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "google-apis-searchconsole_v1", ">= 0.15"
  spec.add_dependency "nokogiri"
  spec.add_dependency "pagy", ">= 43.0"
end

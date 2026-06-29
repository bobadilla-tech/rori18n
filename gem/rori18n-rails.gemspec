require_relative "lib/rori18n/version"

Gem::Specification.new do |s|
  s.name        = "rori18n-rails"
  s.version     = Rori18n::VERSION
  s.authors     = ["Eliaz Bobadilla"]
  s.email       = ["eliaz.bobadilladev@gmail.com"]
  s.summary     = "Use rori18n Go CLI as a Rails development dependency"
  s.description = "Wraps the rori18n Go CLI tool so it behaves like a native Rails dev dependency. " \
                  "Downloads the correct binary on first run. No manual installation required."
  s.homepage    = "https://github.com/bobadilla-tech/rori18n"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.files = Dir[
    "lib/**/*",
    "exe/*",
    "*.md",
    "*.gemspec",
  ]

  s.executables   = ["rori18n"]
  s.require_paths = ["lib"]

  s.metadata = {
    "source_code_uri" => "https://github.com/bobadilla-tech/rori18n",
    "changelog_uri"   => "https://github.com/bobadilla-tech/rori18n/releases",
  }
end

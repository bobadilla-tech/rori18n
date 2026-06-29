require_relative "lib/rori18n/version"

Gem::Specification.new do |s|
  s.name        = "rori18n-rails"
  s.version     = Rori18n::VERSION
  s.authors     = ["Eliaz Bobadilla"]
  s.email       = ["eliaz.bobadilladev@gmail.com"]
  s.summary     = "Production-grade Rails i18n toolchain: extract, inject, translate, deduplicate, refactor"
  s.description = "rori18n replaces i18n-tasks write commands and adds what it lacks: automatic " \
                  "hardcoded-string extraction from ERB, t() call injection, ERB fragment merging, " \
                  "Google Cloud Translation with brand-name protection, key deduplication, and " \
                  "atomic key renaming across YAML and source. Built at Bobadilla Technologies and " \
                  "running in production across multiple Rails apps."
  s.homepage    = "https://github.com/bobadilla-tech/rori18n"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.files = Dir[
    "lib/**/*",
    "exe/*",
    "*.md",
    "*.gemspec",
  ]

  s.bindir        = "exe"
  s.executables   = ["rori18n"]
  s.require_paths = ["lib"]

  s.metadata = {
    "source_code_uri" => "https://github.com/bobadilla-tech/rori18n",
    "changelog_uri"   => "https://github.com/bobadilla-tech/rori18n/releases",
  }
end

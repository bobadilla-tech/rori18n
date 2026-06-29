require_relative "lib/rori18n/version"

Gem::Specification.new do |s|
  s.name        = "rori18n-rails"
  s.version     = Rori18n::VERSION
  s.authors     = ["Eliaz Bobadilla"]
  s.email       = ["eliaz.bobadilladev@gmail.com"]
  s.summary     = "Rails i18n toolchain: extract strings, inject t() calls, translate, prune, refactor keys"
  s.description = "rori18n is a Rails i18n CLI that replaces i18n-tasks write commands and adds " \
                  "capabilities it lacks: automatic hardcoded-string extraction from ERB, t() call " \
                  "injection, ERB fragment merging, Google Cloud Translation, deduplication, and " \
                  "key refactoring. "
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

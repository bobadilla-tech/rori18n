require "rails/generators"

module Rori18n
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates bin/rori18n binstub in your Rails app"

      def create_binstub
        template "binstub.tt", "bin/rori18n"
        chmod "bin/rori18n", 0o755
      end

      def print_instructions
        say "\n"
        say "  rori18n installed!", :green
        say "\n"
        say "  Usage:"
        say "    bin/rori18n report --root ."
        say "    bin/rori18n generate --fix --root ."
        say "    bin/rori18n translate --root . --to es,fr"
        say "\n"
        say "  Or via Rake:"
        say "    bundle exec rake rori18n:run ARGS='generate --fix --root .'"
        say "\n"
        say "  The Go binary is cached at ~/.rori18n/bin/ and downloaded on first run."
        say "  Add that path to .gitignore if you don't want it tracked."
        say "\n"
      end
    end
  end
end

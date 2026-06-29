namespace :rori18n do
  desc "Run rori18n CLI. Set ARGS='generate --fix' or any subcommand."
  task :run do
    require "rori18n-rails"
    args = (ENV["ARGS"] || "").split
    if args.empty?
      $stderr.puts "Usage: bundle exec rake rori18n:run ARGS='<command> [flags]'"
      $stderr.puts "Commands: report, generate, merge-fragments, lint, audit, " \
                   "add-key, prune, translate, analyze, consolidate, refactor-key"
      exit 1
    end
    Rori18n::Runner.run(args)
  end

  desc "Download the rori18n binary without running a command"
  task :install do
    require "rori18n-rails"
    Rori18n::Installer.install!
    puts "rori18n binary ready: #{Rori18n::Installer.binary_path}"
  end
end

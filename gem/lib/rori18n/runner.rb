module Rori18n
  module Runner
    def self.run(args = ARGV)
      Installer.install!
      exec(Installer.binary_path, *args.map(&:to_s))
    end
  end
end

require "rbconfig"

module Rori18n
  module Platform
    SUPPORTED = {
      ["darwin", "arm64"]  => "rori18n_darwin_arm64",
      ["darwin", "x86_64"] => "rori18n_darwin_amd64",
      ["linux",  "x86_64"] => "rori18n_linux_amd64",
    }.freeze

    def self.asset_name
      os  = normalize_os(RbConfig::CONFIG["host_os"])
      cpu = RbConfig::CONFIG["host_cpu"]
      SUPPORTED.fetch([os, cpu]) do
        raise Rori18n::Error,
          "Unsupported platform: #{os}-#{cpu}. " \
          "Supported: #{SUPPORTED.keys.map { |k| k.join('-') }.join(', ')}"
      end
    end

    def self.normalize_os(raw)
      case raw
      when /darwin/ then "darwin"
      when /linux/  then "linux"
      else raw.split("-").first
      end
    end
    private_class_method :normalize_os
  end
end

require "fileutils"
require "net/http"
require "tmpdir"
require "uri"

module Rori18n
  module Installer
    GITHUB_REPO = "bobadilla-tech/rori18n"

    def self.cache_dir
      File.expand_path("~/.rori18n/bin")
    end

    def self.binary_path
      File.join(cache_dir, "rori18n-#{CLI_VERSION}-#{Platform.asset_name}")
    end

    def self.installed?
      File.exist?(binary_path) && File.executable?(binary_path)
    end

    def self.install!
      return if installed?

      asset = Platform.asset_name
      url   = "https://github.com/#{GITHUB_REPO}/releases/download/v#{CLI_VERSION}/#{asset}"

      $stderr.puts "[rori18n] Downloading binary for #{asset} (v#{CLI_VERSION})..."
      $stderr.puts "[rori18n] Source: #{url}"

      FileUtils.mkdir_p(cache_dir)

      download(url, binary_path)
      FileUtils.chmod(0o755, binary_path)

      $stderr.puts "[rori18n] Installed to #{binary_path}"
    rescue Rori18n::Error
      raise
    rescue => e
      raise Rori18n::Error, "Failed to install rori18n binary: #{e.message}\n" \
        "You can manually download from https://github.com/#{GITHUB_REPO}/releases"
    end

    def self.download(url, dest)
      uri = URI.parse(url)
      tmp = "#{dest}.tmp"

      begin
        fetch(uri, tmp)
        size = File.size(tmp)
        raise Rori18n::Error, "Downloaded file is empty (#{url})" if size.zero?
        FileUtils.mv(tmp, dest)
      ensure
        File.unlink(tmp) if File.exist?(tmp)
      end
    end
    private_class_method :download

    def self.fetch(uri, dest, redirect_limit = 5)
      raise Rori18n::Error, "Too many redirects for #{uri}" if redirect_limit.zero?

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          case response
          when Net::HTTPSuccess
            File.open(dest, "wb") { |f| response.read_body { |chunk| f.write(chunk) } }
          when Net::HTTPRedirection
            fetch(URI.parse(response["location"]), dest, redirect_limit - 1)
          else
            raise Rori18n::Error,
              "HTTP #{response.code} downloading rori18n binary from #{uri}\n" \
              "Check that v#{CLI_VERSION} exists at https://github.com/#{GITHUB_REPO}/releases"
          end
        end
      end
    end
    private_class_method :fetch
  end
end

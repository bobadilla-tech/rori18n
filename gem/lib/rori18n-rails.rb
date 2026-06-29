require "rori18n/version"

module Rori18n
  class Error < StandardError; end
end

require "rori18n/platform"
require "rori18n/installer"
require "rori18n/runner"

if defined?(Rails::Railtie)
  require "rori18n/railtie"
end

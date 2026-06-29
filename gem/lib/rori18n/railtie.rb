require "rails/railtie"

module Rori18n
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/rori18n.rake", __dir__)
    end
  end
end

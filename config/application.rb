require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module AcmeDispatch
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # Domain code lives in packs (see packwerk.yml). packs/core is plain Ruby;
    # packs/web adds controllers, helpers and views on top of the host app.
    config.autoload_paths << root.join("packs/core/lib")
    config.eager_load_paths << root.join("packs/core/lib")
    %w[controllers helpers].each do |layer|
      config.autoload_paths << root.join("packs/web/app", layer)
      config.eager_load_paths << root.join("packs/web/app", layer)
    end
    config.paths["app/views"] << "packs/web/app/views"

    config.generators.system_tests = nil
  end
end

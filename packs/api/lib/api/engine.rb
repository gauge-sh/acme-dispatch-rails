module Api
  class Engine < ::Rails::Engine
    isolate_namespace Api

    # Mounting from in here keeps the host's routes file free of engine
    # constants, so the package boundary holds.
    initializer "api.mount" do |app|
      app.routes.append do
        mount Api::Engine => "/api"
      end
    end
  end
end

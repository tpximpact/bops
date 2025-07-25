# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def json_fixture(name, **opts)
      JSON.parse(BopsSubmissions::Engine.root.join("spec", "fixtures", name).read, **opts)
    end

    def json_fixture_api(name, **opts)
      JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", "odp", name).read, **opts)
    end

    def zip_fixture(name)
      BopsSubmissions::Engine.root.join("spec", "fixtures", "files", name).to_s
    end
  end

  config.extend(helpers)
  config.include(helpers)
end

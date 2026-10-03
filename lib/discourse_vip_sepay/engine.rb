# frozen_string_literal: true

module ::DiscourseVipSepay
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseVipSepay

    config.autoload_paths << File.join(config.root, "lib")
  end
end

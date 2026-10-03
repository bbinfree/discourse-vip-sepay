# frozen_string_literal: true

# name: discourse-vip-sepay
# about: VIP memberships for Discourse using Vietnamese bank-transfer payments through SePay/VietQR.
# version: 2.2.1
# authors: Discourse VIP SePay contributors
# url: https://github.com/bbinfree/discourse-vip-sepay
# required_version: 2026.1.0

enabled_site_setting :vip_sepay_enabled
add_admin_route "discourse_vip_sepay.admin.title", "discourse-vip-sepay", use_new_show_route: true

register_asset "stylesheets/vip-sepay.scss"

module ::DiscourseVipSepay
  PLUGIN_NAME = "discourse-vip-sepay"
  VERSION = "2.2.1"
end

require_relative "lib/discourse_vip_sepay/engine"

# frozen_string_literal: true

# name: discourse-vip-sepay
# about: VIP memberships for Discourse using Vietnamese bank-transfer payments through SePay/VietQR.
# version: 2.3.0
# authors: Discourse VIP SePay contributors
# url: https://github.com/bbinfree/discourse-vip-sepay
# required_version: 2026.1.0

# IMPORTANT: Do not call enabled_site_setting here.
# A missing/malformed setting must never prevent Discourse itself from booting.
# Runtime code uses DiscourseVipSepay::Settings.enabled? with safe defaults.

add_admin_route "discourse_vip_sepay.admin.title", "discourse-vip-sepay", use_new_show_route: true
register_asset "stylesheets/vip-sepay.scss"

require_relative "lib/discourse_vip_sepay/settings"

module ::DiscourseVipSepay
  PLUGIN_NAME = "discourse-vip-sepay"
  VERSION = "2.3.0"
end

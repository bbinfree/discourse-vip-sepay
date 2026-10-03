# frozen_string_literal: true

module ::DiscourseVipSepay
  module Settings
    DEFAULTS = {
      vip_sepay_enabled: false,
      vip_sepay_bank_name: "",
      vip_sepay_bank_bin: "",
      vip_sepay_bank_template: "compact2",
      vip_sepay_account_number: "",
      vip_sepay_account_holder: "",
      vip_sepay_payment_prefix: "VIP",
      vip_sepay_webhook_secret: "",
      vip_sepay_webhook_tolerance_seconds: 300,
      vip_sepay_order_expiry_minutes: 15,
      vip_sepay_extend_existing: true,
      vip_sepay_replace_different_group: true,
      vip_sepay_require_exact_amount: true,
      vip_sepay_cleanup_paid_orders_days: 365,
      vip_sepay_cleanup_audit_days: 180,
      vip_sepay_reconciliation_enabled: false,
      vip_sepay_api_token: "",
      vip_sepay_api_base_url: "https://userapi.sepay.vn/v2",
      vip_sepay_reconciliation_days: 2,
      vip_sepay_reconciliation_per_page: 100,
      vip_sepay_http_timeout_seconds: 10,
    }.freeze

    module_function

    def get(name)
      key = name.to_sym
      return DEFAULTS[key] unless DEFAULTS.key?(key)

      if defined?(::SiteSetting) && ::SiteSetting.respond_to?(key)
        ::SiteSetting.public_send(key)
      else
        DEFAULTS[key]
      end
    rescue StandardError => e
      Rails.logger.warn("[vip-sepay] unable to read site setting #{key}: #{e.class}: #{e.message}") if defined?(Rails)
      DEFAULTS[key]
    end

    def enabled?
      get(:vip_sepay_enabled) == true
    end

    DEFAULTS.each_key do |key|
      define_singleton_method(key) { get(key) }
    end
  end
end

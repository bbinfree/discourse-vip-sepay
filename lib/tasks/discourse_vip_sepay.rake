# frozen_string_literal: true
namespace :discourse_vip_sepay do
  desc "Expire VIP orders/subscriptions and clean old plugin data"
  task maintenance: :environment do
    DiscourseVipSepay::CleanupService.run!
    puts "VIP SePay maintenance completed."
  end


  desc "Prepare VIP SePay for safe removal: disable processing and expire pending orders"
  task uninstall_prepare: :environment do
    if SiteSetting.respond_to?(:vip_sepay_enabled=)
      SiteSetting.vip_sepay_enabled = false
    end
    if defined?(Jobs::DiscourseVipSepay::VipSepayExpireOrder)
      Jobs.cancel_scheduled_job(Jobs::DiscourseVipSepay::VipSepayExpireOrder)
    end
    if defined?(Jobs::DiscourseVipSepay::VipSepayExpireSubscription)
      Jobs.cancel_scheduled_job(Jobs::DiscourseVipSepay::VipSepayExpireSubscription)
    end
    if ActiveRecord::Base.connection.data_source_exists?("vip_sepay_orders")
      DiscourseVipSepay::VipSepayOrder.pending.update_all(status: "cancelled", cancelled_at: Time.current, updated_at: Time.current)
    end
    if ENV["REMOVE_PLUGIN_MEMBERSHIPS"] == "YES" && ActiveRecord::Base.connection.data_source_exists?("vip_sepay_subscriptions")
      DiscourseVipSepay::VipSepaySubscription.where(status: "active", membership_added_by_plugin: true).find_each do |subscription|
        if subscription.group_id && subscription.user_id && subscription.group.users.exists?(subscription.user_id)
          subscription.group.remove(subscription.user)
        end
        subscription.update_columns(status: "cancelled", cancelled_at: Time.current, updated_at: Time.current)
      end
    end
    puts "VIP SePay disabled; pending orders cancelled; scheduled VIP jobs cancelled."
    puts "Plugin-owned memberships were removed." if ENV["REMOVE_PLUGIN_MEMBERSHIPS"] == "YES"
  end

  desc "Permanently purge all data owned by Discourse VIP SePay"
  task purge: :environment do
    abort "Set CONFIRM=YES to purge Discourse VIP SePay data" unless ENV["CONFIRM"] == "YES"
    [DiscourseVipSepay::VipSepayAuditLog, DiscourseVipSepay::VipSepayTransaction, DiscourseVipSepay::VipSepaySubscription, DiscourseVipSepay::VipSepayOrder, DiscourseVipSepay::VipSepayPlan].each { |klass| klass.delete_all }
    if ActiveRecord::Base.connection.data_source_exists?("site_settings")
      setting_names = %w[vip_sepay_enabled vip_sepay_bank_name vip_sepay_bank_bin vip_sepay_bank_template vip_sepay_account_number vip_sepay_account_holder vip_sepay_payment_prefix vip_sepay_webhook_secret vip_sepay_webhook_tolerance_seconds vip_sepay_order_expiry_minutes vip_sepay_extend_existing vip_sepay_replace_different_group vip_sepay_require_exact_amount vip_sepay_cleanup_paid_orders_days vip_sepay_cleanup_audit_days vip_sepay_reconciliation_enabled vip_sepay_api_token vip_sepay_api_base_url vip_sepay_reconciliation_days vip_sepay_reconciliation_per_page vip_sepay_http_timeout_seconds]
      SiteSetting.where(name: setting_names).delete_all
    end
    puts "Discourse VIP SePay data purged. Discourse users, posts, groups and categories were not deleted."
  end
end


namespace :discourse_vip_sepay do
  desc "Reconcile recent SePay transactions through API v2"
  task reconcile: :environment do
    result = DiscourseVipSepay::ReconciliationService.run!
    puts result.to_json
  end
end

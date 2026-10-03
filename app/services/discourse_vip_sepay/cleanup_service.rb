# frozen_string_literal: true
module ::DiscourseVipSepay
  class CleanupService
    def self.run!
      DiscourseVipSepay::ExpiryService.expire_orders!
      DiscourseVipSepay::ExpiryService.expire_subscriptions!
      order_cutoff = DiscourseVipSepay::Settings.vip_sepay_cleanup_paid_orders_days.to_i.days.ago
      DiscourseVipSepay::VipSepayOrder.where(status: %w[paid cancelled expired]).where("updated_at < ?", order_cutoff).delete_all
      DiscourseVipSepay::VipSepayTransaction.where("created_at < ?", order_cutoff).delete_all
      DiscourseVipSepay::VipSepayAuditLog.where("created_at < ?", DiscourseVipSepay::Settings.vip_sepay_cleanup_audit_days.to_i.days.ago).delete_all
    end
  end
end

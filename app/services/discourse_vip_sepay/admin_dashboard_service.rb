# frozen_string_literal: true

module ::DiscourseVipSepay
  class AdminDashboardService
    def self.summary(now: Time.current)
      paid = DiscourseVipSepay::VipSepayOrder.where(status: "paid")
      active = DiscourseVipSepay::VipSepaySubscription.active
      {
        generated_at: now,
        plans: DiscourseVipSepay::VipSepayPlan.where(active: true).count,
        pending_orders: DiscourseVipSepay::VipSepayOrder.pending.where("expires_at > ?", now).count,
        paid_orders: paid.count,
        active_memberships: active.count,
        revenue_vnd: paid.sum(:amount_vnd),
        today_revenue_vnd: paid.where("paid_at >= ?", now.beginning_of_day).sum(:amount_vnd),
        expiring_7_days: active.where("expires_at <= ?", 7.days.from_now).count,
        failed_transactions: DiscourseVipSepay::VipSepayTransaction.where(status: %w[ignored failed]).where("created_at >= ?", 7.days.ago).count
      }
    end
  end
end

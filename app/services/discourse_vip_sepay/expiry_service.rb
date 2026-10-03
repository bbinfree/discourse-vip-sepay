# frozen_string_literal: true
module ::DiscourseVipSepay
  class ExpiryService
    def self.expire_orders!
      DiscourseVipSepay::VipSepayOrder.pending.where("expires_at <= ?", Time.current).find_each do |order|
        order.update!(status: "expired")
        DiscourseVipSepay::VipSepayAuditLog.create!(user_id: order.user_id, action: "order_expired", resource_type: "DiscourseVipSepay::VipSepayOrder", resource_id: order.id)
      end
    end
    def self.expire_subscriptions!
      DiscourseVipSepay::VipSepaySubscription.where(status: "active").where("expires_at <= ?", Time.current).find_each { |s| DiscourseVipSepay::MembershipService.expire!(s) }
    end
  end
end

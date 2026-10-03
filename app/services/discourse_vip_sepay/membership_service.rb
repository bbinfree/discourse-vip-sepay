# frozen_string_literal: true
module ::DiscourseVipSepay
  class MembershipService
    def self.activate!(order:, now: Time.current)
      user, plan = order.user, order.plan
      active = DiscourseVipSepay::VipSepaySubscription.active.where(user_id: user.id).order(expires_at: :desc).first
      start_at = now
      inherited_plugin_membership = false
      if active && active.group_id == plan.group_id && DiscourseVipSepay::Settings.vip_sepay_extend_existing
        start_at = active.expires_at
        inherited_plugin_membership = active.membership_added_by_plugin
        active.update!(status: "replaced")
      elsif active && DiscourseVipSepay::Settings.vip_sepay_replace_different_group
        remove_if_owned_by_plugin(active)
        active.update!(status: "replaced")
      end
      expiry = start_at + plan.duration_days.days
      added = false
      unless plan.group.users.exists?(user.id)
        plan.group.add(user)
        added = true
      end
      subscription = DiscourseVipSepay::VipSepaySubscription.create!(user_id: user.id, plan_id: plan.id, group_id: plan.group_id, starts_at: start_at, expires_at: expiry, status: "active", order_id: order.id, membership_added_by_plugin: (added || inherited_plugin_membership))
      DiscourseVipSepay::VipSepayAuditLog.create!(user_id: user.id, action: "vip_activated", resource_type: "DiscourseVipSepay::VipSepaySubscription", resource_id: subscription.id, details: { group_id: plan.group_id, expires_at: expiry }.to_json)
      Jobs.enqueue_at(expiry, Jobs::DiscourseVipSepay::VipSepayExpireSubscription, subscription_id: subscription.id)
      subscription
    end
    def self.expire!(subscription)
      return unless subscription.status == "active"
      remove_if_owned_by_plugin(subscription)
      subscription.update!(status: "expired")
      DiscourseVipSepay::VipSepayAuditLog.create!(user_id: subscription.user_id, action: "vip_expired", resource_type: "DiscourseVipSepay::VipSepaySubscription", resource_id: subscription.id)
    end
    def self.cancel!(subscription)
      return unless subscription.status == "active"
      remove_if_owned_by_plugin(subscription)
      subscription.update!(status: "cancelled", cancelled_at: Time.current)
      DiscourseVipSepay::VipSepayAuditLog.create!(user_id: subscription.user_id, action: "vip_cancelled", resource_type: "DiscourseVipSepay::VipSepaySubscription", resource_id: subscription.id)
    end

    def self.extend!(subscription, days)
      raise ArgumentError, "subscription is not active" unless subscription.status == "active"
      subscription.update!(expires_at: subscription.expires_at + days.days)
      Jobs.enqueue_at(subscription.expires_at, Jobs::DiscourseVipSepay::VipSepayExpireSubscription, subscription_id: subscription.id)
    end

    def self.remove_if_owned_by_plugin(subscription)
      if subscription.membership_added_by_plugin && subscription.group.users.exists?(subscription.user_id)
        subscription.group.remove(subscription.user)
      end
    end
  end
end

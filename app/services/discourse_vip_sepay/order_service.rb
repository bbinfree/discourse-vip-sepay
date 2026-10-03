# frozen_string_literal: true

require "securerandom"

module ::DiscourseVipSepay
  class OrderService
    def self.create!(user:, plan:)
      raise I18n.t("discourse_vip_sepay.errors.invalid_plan") unless plan&.active?
      raise I18n.t("discourse_vip_sepay.errors.invalid_plan") unless plan.price_vnd.to_i.positive? && plan.duration_days.to_i.positive?

      expire_stale_pending_orders!(user)

      existing = DiscourseVipSepay::VipSepayOrder.pending.where(user_id: user.id).where("expires_at > ?", Time.current).order(id: :desc).first
      return existing if existing

      prefix = SiteSetting.vip_sepay_payment_prefix.to_s.upcase.gsub(/[^A-Z0-9]/, "").first(12)
      code = nil
      20.times do
        candidate = "#{prefix.presence || 'VIP'}#{Time.current.strftime('%y%m%d')}#{SecureRandom.hex(4).upcase}"
        unless DiscourseVipSepay::VipSepayOrder.exists?(order_code: candidate)
          code = candidate
          break
        end
      end
      raise "Unable to allocate unique payment code" unless code

      order = DiscourseVipSepay::VipSepayOrder.create!(
        order_code: code,
        user_id: user.id,
        plan_id: plan.id,
        amount_vnd: plan.price_vnd,
        status: "pending",
        expires_at: SiteSetting.vip_sepay_order_expiry_minutes.to_i.minutes.from_now,
      )

      DiscourseVipSepay::VipSepayAuditLog.create!(
        user_id: user.id,
        action: "order_created",
        resource_type: "DiscourseVipSepay::VipSepayOrder",
        resource_id: order.id,
        details: { plan_id: plan.id, amount_vnd: order.amount_vnd }.to_json,
      )

      Jobs.enqueue_at(order.expires_at, Jobs::DiscourseVipSepay::VipSepayExpireOrder, order_id: order.id)
      order
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def self.expire_stale_pending_orders!(user)
      DiscourseVipSepay::VipSepayOrder.pending.where(user_id: user.id).where("expires_at <= ?", Time.current).find_each do |order|
        order.update_columns(status: "expired", updated_at: Time.current)
      end
    end
    private_class_method :expire_stale_pending_orders!
  end
end

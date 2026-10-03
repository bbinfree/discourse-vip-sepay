# frozen_string_literal: true
module ::DiscourseVipSepay
  class VipSepaySubscription < ActiveRecord::Base
  self.table_name = "vip_sepay_subscriptions"
  belongs_to :user
  belongs_to :plan, class_name: "DiscourseVipSepay::VipSepayPlan"
  belongs_to :group, class_name: "Group", foreign_key: :group_id
  belongs_to :order, class_name: "DiscourseVipSepay::VipSepayOrder", optional: true
  scope :active, -> { where(status: "active").where("expires_at > ?", Time.current) }
end
  end

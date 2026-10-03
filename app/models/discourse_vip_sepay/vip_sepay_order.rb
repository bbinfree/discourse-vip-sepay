# frozen_string_literal: true
module ::DiscourseVipSepay
  class VipSepayOrder < ActiveRecord::Base
  self.table_name = "vip_sepay_orders"
  belongs_to :user
  belongs_to :plan, class_name: "DiscourseVipSepay::VipSepayPlan"
  has_many :subscriptions, class_name: "DiscourseVipSepay::VipSepaySubscription", foreign_key: :order_id
  has_one :transaction_record, class_name: "DiscourseVipSepay::VipSepayTransaction", foreign_key: :order_id
  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :expired, -> { where(status: "expired") }
  def paid? = status == "paid"
end
  end

# frozen_string_literal: true

module ::DiscourseVipSepay
  class VipSepayPlan < ::ActiveRecord::Base
    self.table_name = "vip_sepay_plans"

    belongs_to :group, class_name: "Group", foreign_key: :group_id
    has_many :orders, class_name: "DiscourseVipSepay::VipSepayOrder", foreign_key: :plan_id, dependent: :restrict_with_exception
    has_many :subscriptions, class_name: "DiscourseVipSepay::VipSepaySubscription", foreign_key: :plan_id, dependent: :restrict_with_exception

    validates :name, :price_vnd, :duration_days, :group_id, presence: true
    validates :price_vnd, numericality: { only_integer: true, greater_than: 0 }
    validates :duration_days, numericality: { only_integer: true, greater_than: 0 }

    scope :visible, -> { where(active: true).order(:position, :id) }
  end
end

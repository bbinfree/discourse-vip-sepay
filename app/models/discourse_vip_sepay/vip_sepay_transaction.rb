# frozen_string_literal: true

module ::DiscourseVipSepay
  class VipSepayTransaction < ::ActiveRecord::Base
    self.table_name = "vip_sepay_transactions"

    validates :sepay_transaction_id, presence: true, uniqueness: true
    belongs_to :order, class_name: "DiscourseVipSepay::VipSepayOrder", optional: true
    belongs_to :user, optional: true

    scope :applied, -> { where(status: "applied") }
    scope :unresolved, -> { where(status: %w[received ignored failed]) }
  end
end

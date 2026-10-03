# frozen_string_literal: true
module ::DiscourseVipSepay
  class VipSepayAuditLog < ActiveRecord::Base
  self.table_name = "vip_sepay_audit_logs"
  belongs_to :user, optional: true
end
  end

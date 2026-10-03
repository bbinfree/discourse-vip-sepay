# frozen_string_literal: true

module ::DiscourseVipSepay
  class ReconciliationService
    def self.run!(days: nil)
      raise "SePay API reconciliation is disabled" unless DiscourseVipSepay::Settings.vip_sepay_reconciliation_enabled

      days = (days || DiscourseVipSepay::Settings.vip_sepay_reconciliation_days.to_i).to_i
      days = [[days, 1].max, 30].min
      to_time = Time.current
      from_time = days.days.ago
      transactions = DiscourseVipSepay::PaymentService.fetch_transactions(from_time: from_time, to_time: to_time)

      result = { ok: true, checked_at: to_time, from: from_time, to: to_time, fetched: transactions.length, applied: 0, ignored: 0, duplicate: 0, errors: 0 }

      transactions.each do |transaction|
        outcome = DiscourseVipSepay::PaymentService.reconcile_transaction!(transaction)
        key = (outcome == :paid ? :applied : outcome)
        result[key] = result.fetch(key, 0) + 1 if result.key?(key)
      rescue StandardError => e
        result[:errors] += 1
        Rails.logger.error("[vip-sepay] reconciliation transaction failed: #{e.class}: #{e.message}")
      end

      DiscourseVipSepay::VipSepayAuditLog.create!(
        action: "reconciliation_completed",
        details: result.to_json,
      )
      result
    end
  end
end

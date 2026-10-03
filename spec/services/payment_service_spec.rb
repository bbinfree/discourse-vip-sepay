# frozen_string_literal: true

require "rails_helper"

describe DiscourseVipSepay::PaymentService do
  describe ".verify_hmac!" do
    it "accepts a valid signature and timestamp" do
      raw = '{"id":1}'
      timestamp = Time.now.to_i.to_s
      secret = "secret"
      SiteSetting.vip_sepay_webhook_secret = secret
      signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{raw}")
      expect(described_class.verify_hmac!(raw, signature, timestamp)).to eq(true)
    end

    it "rejects a stale timestamp" do
      SiteSetting.vip_sepay_webhook_secret = "secret"
      timestamp = (Time.now.to_i - 100_000).to_s
      signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "secret", "#{timestamp}.body")
      expect(described_class.verify_hmac!("body", signature, timestamp)).to eq(false)
    end
  end

  describe ".normalize_payload" do
    it "normalizes webhook and API v2 transaction shapes" do
      webhook = described_class.normalize_payload(
        "id" => "tx-1",
        "transferAmount" => 99000,
        "transferType" => "in",
        "code" => "VIP260101ABC",
        "content" => "VIP260101ABC",
        "accountNumber" => "0123456789",
        "referenceCode" => "REF-1",
      )
      api = described_class.normalize_payload(
        "id" => "tx-2",
        "amount_in" => 120000,
        "transfer_type" => "in",
        "code" => "VIP260101XYZ",
        "transaction_content" => "VIP260101XYZ",
        "account_number" => "0123456789",
        "reference_number" => "REF-2",
      )

      expect(webhook[:transaction_id]).to eq("tx-1")
      expect(webhook[:amount_vnd]).to eq(99_000)
      expect(api[:transaction_id]).to eq("tx-2")
      expect(api[:amount_vnd]).to eq(120_000)
    end
  end
end

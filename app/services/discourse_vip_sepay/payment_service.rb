# frozen_string_literal: true

require "openssl"
require "uri"
require "net/http"

module ::DiscourseVipSepay
  class PaymentService
    class VerificationError < StandardError; end

    def self.verify_hmac!(raw_body, signature, timestamp)
      secret = SiteSetting.vip_sepay_webhook_secret.to_s
      return false if secret.blank? || signature.blank? || timestamp.blank?

      ts = Integer(timestamp, exception: false)
      tolerance = [SiteSetting.vip_sepay_webhook_tolerance_seconds.to_i, 1].max
      return false unless ts && (Time.now.to_i - ts).abs <= tolerance

      provided = signature.to_s.sub(/\Asha256=/i, "")
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{raw_body}")
      return false unless provided.match?(/\A\h{64}\z/)

      Rack::Utils.secure_compare(expected, provided)
    end

    def self.apply!(payload, source: "webhook")
      normalized = normalize_payload(payload)
      tx_id = normalized.fetch(:transaction_id)
      existing = DiscourseVipSepay::VipSepayTransaction.find_by(sepay_transaction_id: tx_id)
      return :duplicate if existing&.status == "applied"

      tx = existing || create_transaction!(normalized, source: source)
      order = find_matching_order(normalized)
      return mark_ignored!(tx, "order_not_found") unless order
      return mark_ignored!(tx, "not_incoming") unless normalized[:transfer_type].blank? || normalized[:transfer_type] == "in"
      return mark_ignored!(tx, "payment_code_mismatch") unless payment_code_matches?(order, normalized)
      return mark_ignored!(tx, "amount_mismatch") if SiteSetting.vip_sepay_require_exact_amount && normalized[:amount_vnd].to_i != order.amount_vnd.to_i
      return mark_ignored!(tx, "account_mismatch") if account_mismatch?(normalized[:account_number])
      return mark_ignored!(tx, "order_not_payable") unless order.status == "pending" && order.expires_at.present? && order.expires_at > Time.current

      ActiveRecord::Base.transaction do
        order.lock!
        return :duplicate if order.paid?

        order.update!(
          status: "paid",
          paid_at: Time.current,
          last_payment_at: Time.current,
          payment_attempts: order.respond_to?(:payment_attempts) ? order.payment_attempts.to_i + 1 : 1,
          sepay_transaction_id: tx_id,
          reference_code: normalized[:reference_code],
          raw_payload: normalized[:raw_payload],
        )

        DiscourseVipSepay::MembershipService.activate!(order: order)
        tx.update!(status: "applied", order_id: order.id, user_id: order.user_id, verification_error: nil)
        DiscourseVipSepay::VipSepayAuditLog.create!(
          user_id: order.user_id,
          action: "payment_applied",
          resource_type: "DiscourseVipSepay::VipSepayOrder",
          resource_id: order.id,
          details: { transaction_id: tx_id, source: source }.to_json,
        )
      end

      :paid
    rescue ActiveRecord::RecordNotUnique
      :duplicate
    end

    def self.reconcile_transaction!(transaction_hash)
      apply!(transaction_hash, source: "reconciliation")
    end

    def self.qr_url(order)
      query = {
        acc: SiteSetting.vip_sepay_account_number,
        bank: SiteSetting.vip_sepay_bank_bin.presence || SiteSetting.vip_sepay_bank_name,
        amount: order.amount_vnd,
        des: order.order_code,
        template: SiteSetting.vip_sepay_bank_template.presence || "compact2",
      }
      "https://vietqr.app/img?#{URI.encode_www_form(query.reject { |_k, v| v.blank? })}"
    end

    def self.fetch_transactions(from_time:, to_time:)
      token = SiteSetting.vip_sepay_api_token.to_s
      raise VerificationError, "SePay API token is not configured" if token.blank?

      base = SiteSetting.vip_sepay_api_base_url.to_s.sub(%r{/\z}, "")
      uri = URI.parse("#{base}/transactions")
      allowed_hosts = %w[userapi.sepay.vn userapi-sandbox.sepay.vn]
      raise VerificationError, "Unsupported SePay API host" unless uri.scheme == "https" && allowed_hosts.include?(uri.host)
      params = {
        transaction_date_from: from_time.strftime("%Y-%m-%d %H:%M:%S"),
        transaction_date_to: to_time.strftime("%Y-%m-%d %H:%M:%S"),
        per_page: [[SiteSetting.vip_sepay_reconciliation_per_page.to_i, 1].max, 100].min,
        page: 1,
      }
      all = []

      loop do
        uri.query = URI.encode_www_form(params)
        response = http_get(uri, token)
        unless response.is_a?(Net::HTTPSuccess)
          raise VerificationError, "SePay API returned HTTP #{response.code}"
        end

        body = JSON.parse(response.body)
        data = Array(body["data"])
        all.concat(data)
        pagination = body.dig("meta", "pagination") || {}
        break unless pagination["has_more"]
        params[:page] += 1
        break if params[:page] > 100
      end

      all
    end

    def self.normalize_payload(payload)
      p = payload.stringify_keys
      {
        transaction_id: (p["id"] || p["transactionId"]).to_s.presence || raise(VerificationError, "missing transaction id"),
        amount_vnd: (p["transferAmount"] || p["amount_in"] || p["amountIn"] || 0).to_i,
        transfer_type: (p["transferType"] || p["transfer_type"] || "").to_s.downcase,
        code: p["code"].to_s.presence,
        content: (p["content"] || p["transaction_content"] || p["transactionContent"] || "").to_s,
        account_number: (p["accountNumber"] || p["account_number"]).to_s.presence,
        reference_code: (p["referenceCode"] || p["reference_number"] || p["referenceNumber"]).to_s.presence,
        transaction_at: parse_time(p["transactionDate"] || p["transaction_date"]),
        gateway: (p["gateway"] || p["bank_brand_name"] || "").to_s,
        bank_account_id: p["bank_account_id"].to_s.presence,
        va_id: p["va_id"].to_s.presence,
        raw_payload: p.to_json,
      }
    end

    def self.create_transaction!(data, source:)
      DiscourseVipSepay::VipSepayTransaction.create!(
        sepay_transaction_id: data[:transaction_id],
        amount_vnd: data[:amount_vnd],
        transfer_type: data[:transfer_type],
        gateway: data[:gateway],
        reference_code: data[:reference_code],
        transaction_at: data[:transaction_at],
        content: data[:content],
        raw_payload: data[:raw_payload],
        status: "received",
        account_number: data[:account_number],
        bank_account_id: data[:bank_account_id],
        va_id: data[:va_id],
        source: source,
      )
    end
    private_class_method :create_transaction!

    def self.find_matching_order(data)
      direct = data[:code].to_s.presence
      order = DiscourseVipSepay::VipSepayOrder.find_by(order_code: direct) if direct
      return order if order

      candidates = data[:content].to_s.scan(/[A-Z0-9]{5,40}/i).uniq
      return if candidates.empty?

      DiscourseVipSepay::VipSepayOrder.pending.where("expires_at > ?", Time.current).where(order_code: candidates).first
    end
    private_class_method :find_matching_order

    def self.payment_code_matches?(order, data)
      return true if data[:code].to_s.casecmp?(order.order_code.to_s)
      data[:content].to_s.match?(Regexp.escape(order.order_code))
    end
    private_class_method :payment_code_matches?

    def self.account_mismatch?(account_number)
      configured = SiteSetting.vip_sepay_account_number.to_s.strip
      configured.present? && account_number.to_s.strip != configured
    end
    private_class_method :account_mismatch?

    def self.mark_ignored!(tx, reason)
      tx.update_columns(status: "ignored", verification_error: reason, updated_at: Time.current)
      :ignored
    end
    private_class_method :mark_ignored!

    def self.http_get(uri, token)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      timeout = [[SiteSetting.vip_sepay_http_timeout_seconds.to_i, 2].max, 60].min
      http.open_timeout = timeout
      http.read_timeout = timeout
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      http.request(request)
    end
    private_class_method :http_get

    def self.parse_time(value)
      return if value.blank?
      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
    private_class_method :parse_time
  end
end

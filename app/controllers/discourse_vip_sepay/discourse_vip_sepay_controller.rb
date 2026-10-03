# frozen_string_literal: true
module ::DiscourseVipSepay
  class DiscourseVipSepayController < ::ApplicationController
  requires_plugin DiscourseVipSepay::PLUGIN_NAME
  requires_login except: [:webhook]
  skip_before_action :verify_authenticity_token, only: [:webhook]

  def index
    plans = DiscourseVipSepay::VipSepayPlan.where(active: true).includes(:group).order(:position, :id)
    render html: <<~HTML.html_safe
      <div class="vip-sepay-page">
        <div class="vip-sepay-page__hero"><h1>VIP</h1><p>Chọn gói và thanh toán bằng chuyển khoản ngân hàng.</p></div>
        <div class="vip-sepay-plans">#{plans.map { |plan| card(plan) }.join}</div>
      </div>
    HTML
  end

  def create_order
    plan = DiscourseVipSepay::VipSepayPlan.where(active: true).find(params.require(:plan_id))
    order = DiscourseVipSepay::OrderService.create!(user: current_user, plan: plan)
    render_json_dump(order_json(order))
  rescue ActiveRecord::RecordNotFound
    render_json_error(I18n.t("discourse_vip_sepay.errors.invalid_plan"), status: 404)
  rescue StandardError => e
    render_json_error(e.message, status: 422)
  end

  def checkout
    order = DiscourseVipSepay::VipSepayOrder.includes(:plan).find_by!(order_code: params[:order_code])
    raise Discourse::InvalidAccess unless order.user_id == current_user.id || current_user.admin?
    render html: <<~HTML.html_safe
      <div class="vip-sepay-checkout" data-order-code="#{ERB::Util.html_escape(order.order_code)}">
        <h1>Thanh toán VIP</h1>
        <p>#{ERB::Util.html_escape(order.plan.name)}</p>
        <strong class="vip-sepay-checkout__amount">#{order.amount_vnd.to_i.to_s(:delimited)} ₫</strong>
        <img class="vip-sepay-checkout__qr" src="#{ERB::Util.html_escape(DiscourseVipSepay::PaymentService.qr_url(order))}" alt="VietQR">
        <p>Nội dung chuyển khoản: <strong>#{ERB::Util.html_escape(order.order_code)}</strong></p>
        <p id="vip-sepay-status">Đang chờ thanh toán…</p>
      </div>
    HTML
  end

  def status
    order = DiscourseVipSepay::VipSepayOrder.find_by!(order_code: params[:order_code])
    raise Discourse::InvalidAccess unless order.user_id == current_user.id || current_user.admin?
    render_json_dump(status: order.status, paid_at: order.paid_at, expires_at: order.expires_at)
  end

  def webhook
    raw = request.raw_post
    unless DiscourseVipSepay::PaymentService.verify_hmac!(raw, request.headers["X-SePay-Signature"], request.headers["X-SePay-Timestamp"])
      return render json: { success: false, error: "invalid_signature" }, status: 401
    end
    payload = JSON.parse(raw)
    result = DiscourseVipSepay::PaymentService.apply!(payload)
    render json: { success: true, result: result.to_s }
  rescue JSON::ParserError
    render json: { success: false, error: "invalid_json" }, status: 400
  rescue StandardError => e
    Rails.logger.error("[vip-sepay] webhook #{e.class}: #{e.message}")
    render json: { success: false, error: "processing_error" }, status: 500
  end

  private
  def card(plan)
    %(<article class="vip-sepay-plan"><h2>#{ERB::Util.html_escape(plan.name)}</h2><div class="vip-sepay-plan__price">#{plan.price_vnd.to_i.to_s(:delimited)} ₫</div><p>#{plan.duration_days} ngày</p><p>#{ERB::Util.html_escape(plan.description.to_s)}</p><button class="btn btn-primary" data-vip-plan="#{plan.id}">Chọn gói</button></article>)
  end
  def order_json(order)
    { id: order.id, order_code: order.order_code, status: order.status, amount_vnd: order.amount_vnd, expires_at: order.expires_at, checkout_url: "/vip/checkout/#{ERB::Util.url_encode(order.order_code)}", qr_url: DiscourseVipSepay::PaymentService.qr_url(order) }
  end
end
  end

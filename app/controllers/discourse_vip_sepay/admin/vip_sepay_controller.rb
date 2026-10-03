# frozen_string_literal: true

module ::DiscourseVipSepay
  module Admin
    class VipSepayController < ::Admin::AdminController
  requires_plugin DiscourseVipSepay::PLUGIN_NAME

  def index
    render json: DiscourseVipSepay::AdminDashboardService.summary
  end

  def plans
    render json: { plans: DiscourseVipSepay::VipSepayPlan.includes(:group).order(:position, :id).map { |p| plan_json(p) } }
  end

  def groups
    render json: { groups: Group.order(:name).limit(1000).map { |g| { id: g.id, name: g.name, user_count: g.users.count } } }
  end

  def create_plan
    plan = DiscourseVipSepay::VipSepayPlan.create!(plan_params)
    audit("plan_created", plan)
    render json: plan_json(plan), status: 201
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: 422
  end

  def update_plan
    plan = DiscourseVipSepay::VipSepayPlan.find(params[:id])
    plan.update!(plan_params)
    audit("plan_updated", plan)
    render json: plan_json(plan)
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: 422
  end

  def destroy_plan
    plan = DiscourseVipSepay::VipSepayPlan.find(params[:id])
    if plan.orders.exists?
      plan.update!(active: false)
      audit("plan_archived", plan)
      render json: { archived: true, id: plan.id }
    else
      plan.destroy!
      audit("plan_deleted", plan)
      render json: { deleted: true, id: params[:id] }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: 404
  end

  def orders
    scope = DiscourseVipSepay::VipSepayOrder.includes(:user, :plan).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    if params[:q].present?
      q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where("order_code ILIKE ?", q)
    end
    render json: { orders: paginate(scope).map { |o| order_json(o) }, meta: pagination(scope) }
  end

  def transactions
    scope = DiscourseVipSepay::VipSepayTransaction.order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    render json: { transactions: paginate(scope).map { |t| transaction_json(t) }, meta: pagination(scope) }
  end

  def subscriptions
    scope = DiscourseVipSepay::VipSepaySubscription.includes(:user, :plan, :group).order(expires_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    render json: { subscriptions: paginate(scope).map { |s| subscription_json(s) }, meta: pagination(scope) }
  end

  def members
    scope = DiscourseVipSepay::VipSepaySubscription.active.includes(:user, :plan, :group).order(expires_at: :asc)
    if params[:q].present?
      q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
      user_ids = User.where("username ILIKE ? OR name ILIKE ?", q, q).pluck(:id)
      scope = scope.where(user_id: user_ids)
    end
    render json: { members: paginate(scope).map { |s| member_json(s) }, meta: pagination(scope) }
  end

  def cancel_order
    order = DiscourseVipSepay::VipSepayOrder.find(params[:id])
    order.update!(status: "cancelled", cancelled_at: Time.current) if order.status == "pending"
    audit("order_cancelled", order)
    render json: order_json(order)
  end

  def cancel_subscription
    subscription = DiscourseVipSepay::VipSepaySubscription.find(params[:id])
    DiscourseVipSepay::MembershipService.cancel!(subscription)
    audit("subscription_cancelled", subscription)
    render json: subscription_json(subscription.reload)
  end

  def extend_subscription
    subscription = DiscourseVipSepay::VipSepaySubscription.find(params[:id])
    days = params.require(:days).to_i
    raise ArgumentError, "days must be positive" unless days.positive? && days <= 3650
    DiscourseVipSepay::MembershipService.extend!(subscription, days)
    audit("subscription_extended", subscription, { days: days })
    render json: subscription_json(subscription.reload)
  rescue ArgumentError => e
    render json: { error: e.message }, status: 422
  end

  def maintenance
    DiscourseVipSepay::CleanupService.run!
    render json: { ok: true }
  end

  def reconcile
    result = DiscourseVipSepay::ReconciliationService.run!
    render json: result
  rescue StandardError => e
    Rails.logger.error("[vip-sepay] admin reconciliation #{e.class}: #{e.message}")
    render json: { ok: false, error: e.message }, status: 422
  end

  private

  def plan_params
    params.require(:plan).permit(:name, :description, :price_vnd, :duration_days, :group_id, :active, :position, :highlight, :sort_label)
  end

  def paginate(scope)
    @page = [params.fetch(:page, 1).to_i, 1].max
    @per_page = [[params.fetch(:per_page, 25).to_i, 1].max, 100].min
    scope.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def pagination(scope)
    { page: @page, per_page: @per_page, total: scope.unscope(:limit, :offset).count }
  end

  def plan_json(p)
    { id: p.id, name: p.name, description: p.description, price_vnd: p.price_vnd, duration_days: p.duration_days,
      group_id: p.group_id, group_name: p.group&.name, active: p.active, position: p.position,
      highlight: p.respond_to?(:highlight) ? p.highlight : false, sort_label: p.respond_to?(:sort_label) ? p.sort_label : nil }
  end

  def order_json(o)
    { id: o.id, order_code: o.order_code, status: o.status, amount_vnd: o.amount_vnd, user_id: o.user_id,
      username: o.user&.username, plan_id: o.plan_id, plan_name: o.plan&.name, created_at: o.created_at,
      expires_at: o.expires_at, paid_at: o.paid_at, reference_code: o.reference_code }
  end

  def transaction_json(t)
    { id: t.id, sepay_transaction_id: t.sepay_transaction_id, order_code: t.order_code, order_id: t.order_id,
      user_id: t.user_id, amount_vnd: t.amount_vnd, transfer_type: t.transfer_type, gateway: t.gateway,
      reference_code: t.reference_code, transaction_at: t.transaction_at, status: t.status, created_at: t.created_at }
  end

  def subscription_json(s)
    { id: s.id, user_id: s.user_id, username: s.user&.username, plan_id: s.plan_id, plan_name: s.plan&.name,
      group_id: s.group_id, group_name: s.group&.name, starts_at: s.starts_at, expires_at: s.expires_at,
      status: s.status, membership_added_by_plugin: s.membership_added_by_plugin, order_id: s.order_id }
  end

  def member_json(s)
    subscription_json(s).merge(name: s.user&.name, avatar_template: s.user&.avatar_template)
  end

  def audit(action, resource, details = nil)
    DiscourseVipSepay::VipSepayAuditLog.create!(user_id: current_user.id, action: action, resource_type: resource.class.name, resource_id: resource.id, details: details&.to_json)
  end
end
  end
  end

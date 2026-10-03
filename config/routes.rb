# frozen_string_literal: true

Discourse::Application.routes.append do
  get "/vip" => "discourse_vip_sepay/discourse_vip_sepay#index"
  get "/vip/checkout/:order_code" => "discourse_vip_sepay/discourse_vip_sepay#checkout"
  post "/vip/orders" => "discourse_vip_sepay/discourse_vip_sepay#create_order"
  get "/vip/orders/:order_code/status" => "discourse_vip_sepay/discourse_vip_sepay#status"
  post "/vip/sepay/webhook" => "discourse_vip_sepay/discourse_vip_sepay#webhook"

  namespace :admin, constraints: StaffConstraint.new do
    get "/vip-sepay.json" => "discourse_vip_sepay/admin/vip_sepay#index"
    get "/vip-sepay/plans.json" => "discourse_vip_sepay/admin/vip_sepay#plans"
    get "/vip-sepay/groups.json" => "discourse_vip_sepay/admin/vip_sepay#groups"
    post "/vip-sepay/plans.json" => "discourse_vip_sepay/admin/vip_sepay#create_plan"
    put "/vip-sepay/plans/:id.json" => "discourse_vip_sepay/admin/vip_sepay#update_plan"
    delete "/vip-sepay/plans/:id.json" => "discourse_vip_sepay/admin/vip_sepay#destroy_plan"
    get "/vip-sepay/orders.json" => "discourse_vip_sepay/admin/vip_sepay#orders"
    get "/vip-sepay/transactions.json" => "discourse_vip_sepay/admin/vip_sepay#transactions"
    get "/vip-sepay/subscriptions.json" => "discourse_vip_sepay/admin/vip_sepay#subscriptions"
    get "/vip-sepay/members.json" => "discourse_vip_sepay/admin/vip_sepay#members"
    post "/vip-sepay/orders/:id/cancel.json" => "discourse_vip_sepay/admin/vip_sepay#cancel_order"
    post "/vip-sepay/subscriptions/:id/cancel.json" => "discourse_vip_sepay/admin/vip_sepay#cancel_subscription"
    post "/vip-sepay/subscriptions/:id/extend.json" => "discourse_vip_sepay/admin/vip_sepay#extend_subscription"
    post "/vip-sepay/maintenance.json" => "discourse_vip_sepay/admin/vip_sepay#maintenance"
    post "/vip-sepay/reconcile.json" => "discourse_vip_sepay/admin/vip_sepay#reconcile"
  end
end

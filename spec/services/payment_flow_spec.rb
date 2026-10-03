# frozen_string_literal: true

require "rails_helper"

RSpec.describe "VIP SePay payment flow" do
  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group) }
  fab!(:plan) do
    DiscourseVipSepay::VipSepayPlan.create!(
      name: "VIP Test",
      price_vnd: 99_000,
      duration_days: 30,
      group_id: group.id,
      active: true,
    )
  end

  before do
    SiteSetting.vip_sepay_require_exact_amount = true
    SiteSetting.vip_sepay_account_number = "0123456789"
    SiteSetting.vip_sepay_payment_prefix = "VIP"
  end

  it "creates one pending order and applies a matching payment only once" do
    first = DiscourseVipSepay::OrderService.create!(user: user, plan: plan)
    second = DiscourseVipSepay::OrderService.create!(user: user, plan: plan)

    expect(second.id).to eq(first.id)
    expect(DiscourseVipSepay::VipSepayOrder.pending.where(user_id: user.id).count).to eq(1)

    payload = {
      "id" => "sepay-test-#{SecureRandom.hex(8)}",
      "transferAmount" => 99_000,
      "transferType" => "in",
      "code" => first.order_code,
      "content" => first.order_code,
      "accountNumber" => "0123456789",
      "referenceCode" => "REF-TEST-1",
    }

    expect(DiscourseVipSepay::PaymentService.apply!(payload)).to eq(:paid)

    first.reload
    expect(first.status).to eq("paid")
    expect(group.users).to include(user)
    expect(first.subscriptions.active.count).to eq(1)
    expect(first.transaction_record.status).to eq("applied")

    expect(DiscourseVipSepay::PaymentService.apply!(payload)).to eq(:duplicate)
    expect(first.reload.subscriptions.count).to eq(1)
  end

  it "rejects a payment with the wrong amount" do
    order = DiscourseVipSepay::OrderService.create!(user: user, plan: plan)
    payload = {
      "id" => "sepay-wrong-#{SecureRandom.hex(8)}",
      "transferAmount" => 98_000,
      "transferType" => "in",
      "code" => order.order_code,
      "content" => order.order_code,
      "accountNumber" => "0123456789",
    }

    expect(DiscourseVipSepay::PaymentService.apply!(payload)).to eq(:ignored)
    expect(order.reload.status).to eq("pending")
    expect(order.transaction_record.verification_error).to eq("amount_mismatch")
  end
end

# frozen_string_literal: true
require "rails_helper"

describe DiscourseVipSepay::VipSepayPlan do
  it "requires a positive price and duration" do
    plan = described_class.new(name: "VIP", price_vnd: 0, duration_days: 0, group_id: 1)
    expect(plan).not_to be_valid
  end
end

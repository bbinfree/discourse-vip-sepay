# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseVipSepay::Settings do
  it "has safe defaults when a site setting is unavailable" do
    allow(SiteSetting).to receive(:respond_to?).and_call_original
    allow(SiteSetting).to receive(:respond_to?).with(:vip_sepay_enabled).and_return(false)

    expect(described_class.enabled?).to eq(false)
    expect(described_class.vip_sepay_order_expiry_minutes).to eq(15)
  end
end

# frozen_string_literal: true

module ::Jobs
  module ::Jobs::DiscourseVipSepay
    class VipSepayExpireOrder < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.vip_sepay_enabled

        order = ::DiscourseVipSepay::VipSepayOrder.find_by(id: args[:order_id])
        return unless order

        ::DiscourseVipSepay::ExpiryService.expire_orders!
      end
    end
  end
end

# frozen_string_literal: true

module ::Jobs
  module ::Jobs::DiscourseVipSepay
    class VipSepayExpireSubscription < ::Jobs::Base
      def execute(args)
        return unless DiscourseVipSepay::Settings.enabled?

        subscription = ::DiscourseVipSepay::VipSepaySubscription.find_by(id: args[:subscription_id])
        return unless subscription

        ::DiscourseVipSepay::MembershipService.expire!(subscription) if subscription.expires_at <= Time.current
      end
    end
  end
end

export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("discourse-vip-sepay", { path: "/discourse-vip-sepay" });
    this.route("discourse-vip-sepay-plans", { path: "/discourse-vip-sepay/plans" });
    this.route("discourse-vip-sepay-orders", { path: "/discourse-vip-sepay/orders" });
    this.route("discourse-vip-sepay-transactions", { path: "/discourse-vip-sepay/transactions" });
    this.route("discourse-vip-sepay-members", { path: "/discourse-vip-sepay/members" });
  },
};

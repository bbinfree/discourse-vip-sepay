import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("discourse-vip-sepay-admin-nav", (api) => {
  if (!api.container.lookup("service:current-user")?.admin) {
    return;
  }

  api.addAdminPluginConfigurationNav({
    label: "discourse_vip_sepay.admin.navigation.dashboard",
    route: "admin.adminPlugins.show.discourse-vip-sepay",
    description: "discourse_vip_sepay.admin.navigation.description",
    icon: "credit-card",
  });
  api.addAdminPluginConfigurationNav({
    label: "discourse_vip_sepay.admin.navigation.plans",
    route: "admin.adminPlugins.show.discourse-vip-sepay-plans",
    description: "discourse_vip_sepay.admin.navigation.plans_description",
    icon: "layer-group",
  });
  api.addAdminPluginConfigurationNav({
    label: "discourse_vip_sepay.admin.navigation.orders",
    route: "admin.adminPlugins.show.discourse-vip-sepay-orders",
    description: "discourse_vip_sepay.admin.navigation.orders_description",
    icon: "receipt",
  });
  api.addAdminPluginConfigurationNav({
    label: "discourse_vip_sepay.admin.navigation.members",
    route: "admin.adminPlugins.show.discourse-vip-sepay-members",
    description: "discourse_vip_sepay.admin.navigation.members_description",
    icon: "users",
  });
});

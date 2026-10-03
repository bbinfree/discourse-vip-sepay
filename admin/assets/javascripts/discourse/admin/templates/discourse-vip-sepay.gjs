import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
export default class VipSepayDashboard extends Component {
  @tracked busy = false; @tracked message;
  @action async runMaintenance() { this.busy=true; try { await ajax("/admin/vip-sepay/maintenance.json", {type:"POST"}); this.message="Đã chạy bảo trì."; } catch (_) { this.message="Bảo trì thất bại."; } finally { this.busy=false; } }
  @action async reconcile() { this.busy=true; try { const result = await ajax("/admin/vip-sepay/reconcile.json", {type:"POST"}); this.message=`Đối soát xong: ${result.applied || 0} giao dịch được áp dụng, ${result.ignored || 0} giao dịch bỏ qua.`; } catch (e) { this.message=e?.jqXHR?.responseJSON?.error || "Đối soát thất bại."; } finally { this.busy=false; } }
  <template>
    <div class="vip-sepay-admin"><div class="vip-sepay-admin__header"><div><h1>{{i18n "discourse_vip_sepay.admin.title"}}</h1><p>Quản lý VIP, đơn hàng, Group và thanh toán SePay.</p></div></div>
    <div class="vip-sepay-kpis"><div class="vip-sepay-kpi"><span>Doanh thu</span><strong>{{@model.revenue_vnd}} ₫</strong></div><div class="vip-sepay-kpi"><span>Hôm nay</span><strong>{{@model.today_revenue_vnd}} ₫</strong></div><div class="vip-sepay-kpi"><span>Đang chờ</span><strong>{{@model.pending_orders}}</strong></div><div class="vip-sepay-kpi"><span>VIP hoạt động</span><strong>{{@model.active_memberships}}</strong></div><div class="vip-sepay-kpi"><span>Sắp hết hạn</span><strong>{{@model.expiring_7_days}}</strong></div></div>
    <div class="vip-sepay-admin__actions"><button class="btn btn-primary" type="button" {{on "click" this.runMaintenance}} disabled={{this.busy}}>Chạy bảo trì</button><button class="btn" type="button" {{on "click" this.reconcile}} disabled={{this.busy}}>Đối soát SePay</button><a class="btn" href="/admin/site_settings/category/vip_sepay">Cấu hình SePay</a><a class="btn" href="/vip">Xem trang VIP</a></div>
    {{#if this.message}}<div class="alert alert-info">{{this.message}}</div>{{/if}}</div>
  </template>
}

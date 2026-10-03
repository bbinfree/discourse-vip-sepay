import { ajax } from "discourse/lib/ajax";
import { apiInitializer } from "discourse/lib/api";

apiInitializer("discourse-vip-sepay-checkout", (api) => {
  api.decorateCookedElement((element) => {
    const buttons = element.querySelectorAll("[data-vip-plan]");
    buttons.forEach((button) => {
      if (button.dataset.vipBound) return;
      button.dataset.vipBound = "1";
      button.addEventListener("click", async () => {
        button.disabled = true;
        try {
          const result = await ajax("/vip/orders", { type: "POST", data: { plan_id: button.dataset.vipPlan } });
          window.location.assign(result.checkout_url);
        } catch (error) {
          button.disabled = false;
          alert(error?.jqXHR?.responseJSON?.errors?.join("\n") || "Không thể tạo đơn thanh toán.");
        }
      });
    });

    const status = element.querySelector("#vip-sepay-status");
    const checkout = element.querySelector(".vip-sepay-checkout[data-order-code]");
    if (status && checkout && !status.dataset.polling) {
      status.dataset.polling = "1";
      const orderCode = checkout.dataset.orderCode;
      const timer = setInterval(async () => {
        try {
          const data = await ajax(`/vip/orders/${encodeURIComponent(orderCode)}/status`);
          status.textContent = data.status === "paid" ? "Thanh toán thành công. VIP đã được kích hoạt." : data.status === "expired" ? "Đơn đã hết hạn." : "Đang chờ thanh toán…";
          if (["paid", "expired", "cancelled"].includes(data.status)) clearInterval(timer);
        } catch (_) {}
      }, 3000);
    }
  });
});

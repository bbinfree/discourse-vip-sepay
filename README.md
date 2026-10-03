# Discourse VIP SePay — 2.2.1

Plugin VIP cho Discourse, lấy cảm hứng từ mô hình **Discourse Subscriptions**, nhưng thanh toán bằng chuyển khoản ngân hàng Việt Nam qua **SePay + VietQR**.

## 0. Cài đặt từ GitHub

Repository chính:

`https://github.com/bbinfree/discourse-vip-sepay`

Trong Discourse Docker:

```bash
cd /var/discourse
./launcher enter app
```

Hoặc thêm repository vào `app.yml` và rebuild Discourse:

```yaml
- git clone https://github.com/bbinfree/discourse-vip-sepay.git
```

Sau đó rebuild và kiểm tra plugin tại `/admin/plugins`.

## 1. Mục tiêu

Plugin được thiết kế để nhiều diễn đàn Việt Nam có thể cài độc lập:

- Mỗi diễn đàn tự cấu hình ngân hàng, SePay Secret và các Group.
- Không hard-code domain `traiviet.net`.
- Gói VIP có thể gắn với bất kỳ Discourse Group nào.
- Group dùng chính cơ chế permission của Discourse để cấp quyền viết bài/category.
- Dữ liệu plugin nằm trong namespace/table riêng.
- Migration chỉ thêm mới, không sửa migration đã phát hành.
- Có purge riêng khi gỡ plugin.

## 2. Luồng thành viên

`/vip` → chọn gói → tạo đơn → VietQR → chuyển khoản → SePay webhook → xác minh HMAC → đối chiếu mã + tiền + tài khoản → khóa giao dịch → đánh dấu Paid → thêm Group → kích hoạt hạn VIP.

Khi hết hạn: job/maintenance xử lý subscription và chỉ gỡ Group nếu membership đó do plugin tạo.

## 3. Admin UI 2.2.1

Truy cập:

`/admin/plugins/discourse-vip-sepay`

Các khu vực:

- Tổng quan
  - Doanh thu tổng
  - Doanh thu hôm nay
  - Đơn chờ
  - VIP đang hoạt động
  - VIP sắp hết hạn
- Gói VIP
  - Tạo gói
  - Giá VND
  - Số ngày
  - Chọn Group
  - Bật/tắt bán
- Đơn hàng
  - Mã đơn
  - Thành viên
  - Gói
  - Số tiền
  - Trạng thái
  - Hủy đơn chờ
- Giao dịch SePay
  - ID SePay
  - Mã đơn
  - Số tiền
  - Gateway
  - Trạng thái
- Thành viên VIP
  - Group
  - Ngày bắt đầu
  - Ngày hết hạn
  - Hủy VIP

## 4. Cấu hình SePay

Site Settings:

- `vip_sepay_enabled`
- `vip_sepay_bank_name`
- `vip_sepay_bank_bin`
- `vip_sepay_bank_template`
- `vip_sepay_account_number`
- `vip_sepay_account_holder`
- `vip_sepay_payment_prefix`
- `vip_sepay_webhook_secret`
- `vip_sepay_webhook_tolerance_seconds`
- `vip_sepay_order_expiry_minutes`
- `vip_sepay_extend_existing`
- `vip_sepay_replace_different_group`
- `vip_sepay_require_exact_amount`

Webhook:

`POST https://TEN-MIEN/vip/sepay/webhook`

Production nên dùng HTTPS + HMAC-SHA256. SePay ký chuỗi `{timestamp}.{raw_body}` và gửi `X-SePay-Signature` cùng `X-SePay-Timestamp`; không được parse rồi serialize lại body trước khi kiểm tra chữ ký.

## 5. Cấu hình Group

Ví dụ:

- VIP 7 ngày → Group `vip-7`
- VIP 30 ngày → Group `vip-30`
- VIP 90 ngày → Group `vip-90`
- VIP 365 ngày → Group `vip-365`

Sau đó vào Category → Security và cấp `Create Topic` cho Group tương ứng.

## 6. Bảo mật

Plugin kiểm tra:

1. HMAC-SHA256.
2. Timestamp chống replay.
3. Transaction ID duy nhất.
4. Database lock khi áp dụng đơn.
5. Mã thanh toán.
6. Số tiền chính xác nếu bật `vip_sepay_require_exact_amount`.
7. Tài khoản nhận tiền nếu payload cung cấp `accountNumber`.
8. Đơn phải còn `pending` và chưa hết hạn.

Không lưu Secret SePay vào source code.

## 7. Gỡ plugin sạch

Không chỉ xóa thư mục plugin.

Chạy:

```bash
cd /var/discourse
./launcher enter app
RAILS_ENV=production CONFIRM=YES bundle exec rake discourse_vip_sepay:purge
exit
```

Sau đó xóa plugin khỏi `app.yml` và rebuild.

Purge chỉ xóa dữ liệu do plugin sở hữu; không xóa User, Topic, Post, Category hoặc Group của Discourse.

## 8. Nâng cấp

Không sửa migration đã phát hành.

Ví dụ:

```text
2.0.0
 ↓
2.1.0
 ↓
2.2.1
 ↓
3.0.0
```

Mỗi thay đổi database tạo migration timestamp mới.

## 9. Kiểm tra trước production

Trên môi trường test:

```bash
ruby -c plugin.rb
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rspec plugins/discourse-vip-sepay/spec
```

Sau đó kiểm thử SePay Test Mode:

1. Tạo webhook test.
2. Chọn HMAC-SHA256.
3. Tạo một gói VIP test.
4. Tạo order.
5. Mô phỏng giao dịch đúng tiền + đúng mã.
6. Kiểm tra Group.
7. Gửi lại cùng transaction ID để kiểm tra duplicate.
8. Gửi sai signature.
9. Gửi timestamp quá cũ.
10. Chạy expiry.

## 10. Điểm mới trong 2.2.1

- Đối soát giao dịch thật qua **SePay API v2**.
- Hỗ trợ Bearer API Token và Production/Sandbox base URL.
- Đối soát theo khoảng thời gian, phân trang tối đa 100 giao dịch/trang.
- Tự backfill giao dịch bị mất webhook và áp dụng lại order nếu đủ điều kiện.
- Lưu `source` (`webhook` hoặc `reconciliation`) và `verification_error`.
- Có nút **Đối soát SePay** trong Admin.
- Có Rake task `discourse_vip_sepay:reconcile`.
- Chống nhiều đơn pending của cùng một user bằng unique partial index.
- Tự đánh dấu các đơn pending đã hết hạn trước khi tạo đơn mới.
- Transaction matching hỗ trợ payload webhook và payload API v2.
- Giới hạn timeout HTTP và số ngày đối soát để tránh gây tải cho diễn đàn.

SePay API v2 dùng Bearer token, endpoint production `https://userapi.sepay.vn/v2`, giới hạn `per_page` tối đa 100 và trả ID giao dịch dạng UUID. Plugin 2.2.1 sử dụng các quy ước này cho reconciliation.

## 11. Cấu hình đối soát 2.2.1

Site Settings mới:

- `vip_sepay_reconciliation_enabled`
- `vip_sepay_api_token` — secret, không đưa lên GitHub
- `vip_sepay_api_base_url` — mặc định `https://userapi.sepay.vn/v2`; Sandbox dùng `https://userapi-sandbox.sepay.vn/v2`
- `vip_sepay_reconciliation_days` — 1–30 ngày
- `vip_sepay_reconciliation_per_page` — 1–100
- `vip_sepay_http_timeout_seconds` — 2–60 giây

Có thể chạy thủ công:

```bash
cd /var/discourse
./launcher enter app
RAILS_ENV=production bundle exec rake discourse_vip_sepay:reconcile
exit
```

Khuyến nghị production chạy đối soát mỗi 15–30 phút bằng cron của server nếu muốn tự động backfill webhook bị mất. SePay khuyến nghị đối soát định kỳ vì webhook có thể bị mất sau thời gian retry.

## 12. Tương thích và kiểm thử 2.2.1

2.2.1 đưa application routes về `config/routes.rb` theo cấu trúc plugin Discourse chuẩn, tránh đăng ký route trùng từ `plugin.rb`. Discourse core hiện mô tả `plugin.rb` là manifest/initializer và hỗ trợ skeleton plugin chuẩn; route của plugin nên được tổ chức riêng trong hệ thống route của plugin.

Trước production cần chạy bộ RSpec của plugin trong chính phiên bản Discourse mục tiêu. Bản phát hành này đã kiểm tra Ruby syntax của toàn bộ file Ruby và JavaScript/GJS syntax, nhưng việc này không thay thế integration test trên instance Discourse thật.

## 13. Phạm vi còn lại của 2.2.1

2.2.1 đã triển khai reconciliation qua SePay API v2. Các hạng mục dưới đây chưa thuộc phạm vi của bản này:

- CSV export.
- Bộ lọc nâng cao theo ngày.
- Dashboard doanh thu theo ngày/tháng.
- Coupon/khuyến mãi.
- Gói dùng thử.
- Gói tự gia hạn nếu triển khai cơ chế thanh toán phù hợp.
- Email/notification khi VIP sắp hết hạn.
- Import/export cấu hình gói.
- Health check SePay.

## 2.2.1 hardening

This release restructures Ruby code around a Rails Engine and Zeitwerk-compatible namespaces/paths, removes the manual `after_initialize` require chain, namespaces plugin models/services/controllers, and keeps scheduled jobs isolated under the plugin job namespace. Public `/vip` URLs and admin endpoints remain unchanged.

The plugin also includes a safe-removal preparation task that disables processing, cancels scheduled VIP jobs, and cancels pending VIP orders before rebuild/removal.

## Safe disable / removal

The plugin is designed so its database tables are isolated under `vip_sepay_*` names and no Discourse core table is altered by the plugin migrations. Removing the plugin from `app.yml` and rebuilding therefore does not require deleting Discourse core data. Discourse's normal plugin removal process is to remove the plugin clone line and rebuild.

Before removal, recommended:

```bash
cd /var/discourse
./launcher enter app
rake discourse_vip_sepay:uninstall_prepare
exit
./launcher rebuild app
```

`uninstall_prepare` disables VIP processing, cancels pending VIP orders, and cancels scheduled VIP expiry jobs. It does **not** delete users, posts, groups, categories, or core Discourse data. If you also want to remove only the group memberships that this plugin itself added, run the task with `REMOVE_PLUGIN_MEMBERSHIPS=YES`. Plugin-owned tables are intentionally retained by normal plugin removal; this allows reinstalling the plugin without losing its data.

If you intentionally want to permanently delete all plugin-owned data, use the separate destructive `purge` task only after making a database backup.

### Architecture

The plugin uses a Rails Engine and namespaced application classes for Rails autoloading, matching the current Discourse plugin guidance. This avoids manual `require_relative` chains and isolates plugin classes from the Discourse root namespace.

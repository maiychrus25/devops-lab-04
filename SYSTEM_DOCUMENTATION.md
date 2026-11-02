# Lab 4 — Tài liệu hệ thống

docs-check: lab4-ansible

Trạng thái: hoàn thành, đã kiểm chứng và dọn tài nguyên — 02/11/2026.

## Phạm vi

Nguồn đề: PhamThuongBlog/VHBTPM_DevOps_2026, commit f4bb72310d326f84bf36b27550dd758f18f54c0a.
Các file chính: `inventory.ini`, `ansible.cfg`, `playbook-webserver.yml`, `playbook-full.yml`.
Control node macOS dùng Ansible community 14.5.0/core 2.21.5, Python 3.12.15 do uv quản lý. Managed nodes dùng image Ubuntu SSH 22.04 AMD64 của đề qua Docker Desktop.

## Kết nối và an toàn

Ba container web-server-1, web-server-2, db-server-1 thuộc network ansible-lab, gắn label devops.lab=lab4-dtc235180104.
SSH lần lượt 127.0.0.1:2201/2202/2203; HTTP 127.0.0.1:8081/8082. Không publish ra LAN; không cần privileged cho image chạy sshd làm PID 1.
User/password root/root chỉ là thông tin demo của container cô lập. Host key dùng accept-new và file riêng ~/.ssh/known_hosts_devops_lab4; không sửa known_hosts dùng chung.
Production là tên group/giá trị config theo bài học, không phải triển khai production thật.

## Luồng thực hành

Chạy setup → inventory/ping → ad-hoc → check mode → web playbook → full playbook → kiểm chứng/idempotency → chụp ảnh → cleanup.
`scripts/setup.sh` từ chối ghi đè container/network trùng tên. `scripts/cleanup.sh` chỉ xóa tài nguyên có label đúng và kiểm tra quyền sở hữu trước khi xóa.
Hai script dừng ngay khi Docker daemon không hoạt động; kiểm thử bằng Docker giả xác nhận không xóa gì khi daemon tắt hoặc tài nguyên không thuộc lab.
Cleanup xác minh lại danh sách container/network trước khi báo thành công; trường hợp daemon mất kết nối giữa chừng cũng phải dừng, được kiểm thử RED→GREEN sau review độc lập.
`make build` kiểm tra inventory và syntax; `make test` kiểm tra phân nhóm, loopback, host keys và phạm vi full playbook; `make lint` kiểm tra syntax shell/YAML và docs-check.

## Khác biệt cần thiết so với mẫu

- Dùng ansible.builtin.default thay callback yaml đã thay đổi ở Ansible mới; dùng ansible_facts thay các fact alias cũ.
- Theo phần hướng dẫn chính: không dùng ufw trong container và không bỏ qua lỗi task.
- Check mode trên máy chưa có Apache chỉ dự báo cài package; các task phụ thuộc dịch vụ/web-root được bỏ qua trong dry-run đó. Chạy thật luôn thực hiện đủ task và không bỏ qua lỗi.
- Full playbook tạo file app/health-check trên cả ba host để lệnh kiểm tra all của đề hoạt động.
- Trang Apache giữ nội dung theo đề, thêm viewport, ngắt dòng và dark/light theo DESIGN.md.

## Kết quả sau thực hành

- Ping qua SSH: 3/3 pong; đủ 10 thao tác ad-hoc thành công.
- Web playbook: 2 hosts, mỗi host ok=5/changed=3/failed=0; full playbook: 3 hosts, mỗi host ok=7/changed=5/failed=0.
- Health-check/config/facts/package checks đạt cả 3 hosts.
- Hai vòng chạy lại cả hai playbook đều changed=0/failed=0/unreachable=0/skipped=0/ignored=0.
- HTTP: vòng 1 200/200 thành công, p95 211,07 ms; vòng 2 600/600 thành công, p95 7,59 ms; concurrency 16.
- Mỗi vòng có 8 kiểm tra trình duyệt trên hai server, desktop/mobile, light/dark; đạt tương phản, không tràn ngang/chồng chữ.
- Đã xóa ba container, network, image và host-key riêng. Năm cổng đều đóng; baseline network/volume được bảo toàn.
- Logs chỉ được chuẩn hóa khoảng trắng cuối dòng; các giá trị và kết quả thực thi được giữ nguyên. Ảnh log ghi rõ nguồn; ảnh web chụp trực tiếp Apache.
- Chưa thực hiện phần mở rộng Role/Vault/Galaxy và chưa upload LMS. docs/ và AGENTS.md giữ local.

## Ghi chú bàn giao mã nguồn

Theo yêu cầu mới của người học: không tạo ZIP. Bàn giao qua repo GitHub devops-lab-04 gồm mã nguồn, helper kiểm tra và tài liệu chạy/học. logs/ và screenshots/ giữ local, không đưa lên Git; README trên GitHub không phụ thuộc ảnh/log local. Thông tin thực hành chi tiết được giữ trong docs/LAB_REPORT.md tại máy.

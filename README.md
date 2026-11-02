# Lab 4 — Quản lý cấu hình hạ tầng với Ansible

**Nịnh Thanh Khương · DTC235180104 · KTPM K22B**

Thực hành theo [hướng dẫn Lab 4](https://github.com/PhamThuongBlog/VHBTPM_DevOps_2026/blob/f4bb72310d326f84bf36b27550dd758f18f54c0a/Labs/B%C3%A0i%204/Lab4_HuongDan.md). Repo nộp mã nguồn, có inventory, hai playbook, script dựng/dọn môi trường và kiểm tra. Đã thực hành thành công ngày 02/11/2026 và dọn tài nguyên.

## Hiểu kiến trúc trước khi chạy

Máy Mac là **control node** chạy Ansible. Ba container Ubuntu là **managed nodes** nhận cấu hình qua SSH, không cần agent Ansible.

```text
Mac + Ansible
  ├─ SSH 127.0.0.1:2201 → web-server-1 → Apache, HTTP :8081
  ├─ SSH 127.0.0.1:2202 → web-server-2 → Apache, HTTP :8082
  └─ SSH 127.0.0.1:2203 → db-server-1  → cấu hình chung + monitoring
```

Tất cả cổng chỉ bind `127.0.0.1`. Nhóm `production` và giá trị `APP_ENV=production` là ví dụ của bài học trên Docker local. Image của đề có user/password demo `root/root`; không dùng cho máy thật hoặc mạng công cộng.

## Mỗi file làm gì?

| File | Trách nhiệm |
|---|---|
| `inventory.ini` | Danh sách host, cổng SSH, nhóm webservers/dbservers/production |
| `ansible.cfg` | Inventory mặc định, timeout, callback, kiểm tra SSH host key |
| `playbook-webserver.yml` | Cài Apache, start/enable service, tạo trang HTML từ facts |
| `playbook-full.yml` | Cài gói chung, tạo config/health-check và cài công cụ monitoring trên cả ba host |
| `scripts/setup.sh` | Tạo ba container và network, từ chối tên tài nguyên đã tồn tại |
| `scripts/cleanup.sh` | Kiểm tra label sở hữu, dọn đúng tài nguyên lab, xác minh kết quả |
| `Makefile` | Các lệnh build/test/lint, không tạo container |
| `SYSTEM_DOCUMENTATION.md` | Chi tiết môi trường, thay đổi so với mẫu và kết quả kiểm chứng |

## Chuẩn bị

Máy đã thực hành dùng Docker Desktop 29.9.2, Ansible community 14.5.0/core 2.21.5, Python control 3.12.15. Managed nodes là Ubuntu 22.04/Python 3.10.12. Image AMD64 chạy mô phỏng trên Mac ARM64.

```bash
# Trên máy mới: cài uv và Docker Desktop trước.
uv tool install --python 3.12 --with-executables-from ansible-core ansible==14.5.0
export PATH="/Applications/Docker.app/Contents/Resources/bin:$HOME/.local/bin:$PATH"
```

Mở Docker Desktop, đợi trạng thái Running và chạy các lệnh dưới đây từ thư mục repo.

## 1. Dựng môi trường và đọc inventory

```bash
bash scripts/setup.sh
ansible-inventory --graph
ansible all -m ping
```

`webservers` gồm hai host; `dbservers` gồm một host. `production:children` gộp cả hai nhóm. Ba host cùng dùng loopback nhưng có cổng SSH khác nhau. Kết quả `pong` xác nhận SSH và Python trên node hoạt động; đây là module ping của Ansible, không phải ICMP ping.

## 2. Thử ad-hoc command

Ad-hoc là thao tác nhanh, chưa cần viết playbook:

```bash
ansible webservers -m command -a hostname
ansible all -m command -a 'df -h /'
ansible all -m apt -a 'name=curl state=present update_cache=yes cache_valid_time=3600'
ansible webservers -m copy -a 'src=hello.txt dest=/tmp/hello.txt mode=0644'
```

Cấu trúc: `ansible <host hoặc group> -m <module> -a '<tham số>'`. `command` chạy lệnh, `apt` quản lý package, `copy` quản lý nội dung file. Dùng `shell` khi cần cú pháp shell như pipe.

## 3. Chạy playbook web server

```bash
ansible-playbook playbook-webserver.yml --syntax-check
ansible-playbook playbook-webserver.yml --check
ansible-playbook playbook-webserver.yml
curl -fsS http://127.0.0.1:8081
curl -fsS http://127.0.0.1:8082
```

Một play chỉ định **hosts**, **vars** và các **tasks**. Mỗi task dùng module để đưa hệ thống về trạng thái mong muốn:

```yaml
- name: Install Apache web server
  ansible.builtin.apt:
    name: "{{ web_package }}"
    state: present
```

`web_package` là biến do playbook khai báo. `state: present` yêu cầu package tồn tại; module sẽ kiểm tra trước khi cài. Các facts như `ansible_facts.hostname` do Ansible thu thập từ managed node; `{{ ... }}` dùng Jinja2 để đưa giá trị vào trang HTML.

`--check` dự báo thay đổi. Trên node chưa có Apache, hai task phụ thuộc service/web-root được bỏ qua riêng trong dry-run; chạy thật thực hiện đủ các task. Để chỉ cấu hình một host:

```bash
ansible-playbook playbook-webserver.yml --limit web-server-1
```

## 4. Cấu hình cả ba host

```bash
ansible-playbook playbook-full.yml
ansible all -m command -a /opt/myapp/health-check.sh
ansible all -m command -a 'cat /opt/myapp/config.env'
ansible all -m setup -a filter=ansible_distribution
```

Full playbook có hai play: cấu hình ứng dụng chung trên `production`, rồi cài monitoring trên `all`. Bài cơ bản chỉ dùng db-server-1 làm managed node cho phần này; không có task cài database engine trong đề.

## 5. Hiểu và thử idempotency

```bash
ansible-playbook playbook-webserver.yml
ansible-playbook playbook-full.yml
```

Khi trạng thái đã đúng, recap có `changed=0`. Ansible vẫn kiểm tra các task và trả `ok`. Các trường cần đọc:

- `ok`: task thực hiện thành công, bao gồm task có thay đổi.
- `changed`: số task đã sửa trạng thái.
- `failed`: task lỗi; `unreachable`: không kết nối được host.
- `skipped`: task bỏ qua do điều kiện hoặc check mode.

**Bài tập tự thử:** đổi một dòng trong nội dung HTML rồi chạy web playbook. Task copy sẽ báo changed. Chạy lại lần nữa để thấy changed=0. Sau đó thử `--limit web-server-1` và so sánh trang ở hai cổng.

## 6. Dọn môi trường

```bash
bash scripts/cleanup.sh
```

Script chỉ xóa ba container/network có label đúng của lab và file SSH host-key riêng. Nếu muốn dọn image đã tải khi không còn container nào sử dụng:

```bash
docker image rm phamthuongdocker/ubuntu-sshd:22.04
```

## Kiểm chứng đã thực hiện

- Ba host trả pong; đủ mười thao tác ad-hoc thành công.
- Lần chạy đầu: web playbook mỗi host ok=5/changed=3; full playbook mỗi host ok=7/changed=5; không failed/unreachable/ignored.
- Hai vòng chạy lại cả hai playbook: changed=0, failed=0 trên mọi host.
- Hai vòng HTTP: 200 và 600 request, không lỗi; 16 kiểm tra desktop/mobile/light/dark đạt, không tràn ngang/chồng chữ.
- Dọn đúng ba container, network, image và host-key riêng; các tài nguyên Docker có sẵn được giữ nguyên.

```bash
make build
make test
make lint
```

Ảnh và logs bằng chứng giữ local, được Git bỏ qua cùng `docs/` và `AGENTS.md`. Phần mở rộng Role/Vault/Galaxy chưa thực hiện.

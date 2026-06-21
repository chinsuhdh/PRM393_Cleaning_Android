# 🧹 PRM393_Cleaning_Android (Frontend)
**Hệ Thống Đặt Lịch Dịch Vụ Vệ Sinh Tích Hợp AI (AI-Powered Cleaning Service Platform)**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

## 📖 Giới thiệu dự án

Đây là repository chứa mã nguồn **Frontend (Mobile App)** của nền tảng kết nối khách hàng và thợ cung cấp dịch vụ vệ sinh. Ứng dụng được xây dựng bằng **Flutter**, giao tiếp với hệ thống Backend ASP.NET Core mạnh mẽ nhằm mang lại trải nghiệm mượt mà, realtime và bảo mật cao. 

Ứng dụng được thiết kế theo kiến trúc module hóa, phục vụ trực tiếp 3 nhóm người dùng trong hệ sinh thái, đồng thời tích hợp sâu với các dịch vụ AI (Matchmaking, Chatbot RAG).

## 🚀 Tính năng chính theo vai trò (Roles)

Ứng dụng hỗ trợ đa luồng nghiệp vụ dựa trên vai trò khi người dùng đăng nhập:

* **🧑‍💻 Client (Khách hàng):**
    * Tìm kiếm và đặt lịch dịch vụ vệ sinh nhanh chóng.
    * Theo dõi trạng thái đơn hàng theo thời gian thực (Real-time).
    * Tương tác với AI Chatbot (RAG Knowledge Base) để nhận tư vấn tự động.
    * Thanh toán trực tuyến (MoMo, VNPay) và đánh giá chất lượng dịch vụ.
* **👷 Worker (Thợ vệ sinh):**
    * Nhận thông báo công việc mới qua hệ thống Push Notification.
    * Xem bản đồ và tọa độ GPS để di chuyển đến vị trí khách hàng.
    * Cập nhật trạng thái công việc và quản lý thu nhập qua ví điện tử.
* **🛡️ Admin (Quản trị viên):**
    * Dashboard giám sát hoạt động hệ thống.
    * Quản lý danh mục dịch vụ và duyệt hồ sơ đăng ký của thợ.

## 🛠 Công nghệ sử dụng (Frontend Stack)

* **Framework:** Flutter (Dart)
* **Real-time Communication:** SignalR Client (Nhận thông báo trạng thái đơn hàng tức thì).
* **Authentication:** JWT (JSON Web Token), OAuth2 (Đăng nhập qua Google, Facebook, Apple).
* **Maps & Geolocation:** Tích hợp SDK bản đồ và định vị GPS cho Worker.
* **CI/CD:** Tự động hóa quá trình kiểm tra và build file APK/AAB bằng GitHub Actions.

*Lưu ý: Ứng dụng được kết nối với Backend ASP.NET Core và cơ sở dữ liệu PostgreSQL (Xem thêm cấu trúc hệ thống tại Repo Backend).*

## ⚙️ Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Yêu cầu hệ thống
* Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (Khuyến nghị phiên bản Stable mới nhất).
* Đã cài đặt Android Studio hoặc VS Code kèm các plugin/extension hỗ trợ Flutter.
* Backend API đang hoạt động (Local hoặc Server).

### 2. Các bước khởi chạy

**Bước 1: Clone repository về máy**
```bash
git clone <URL_REPO_FRONTEND_CỦA_BẠN>
cd PRM393_Cleaning_Android

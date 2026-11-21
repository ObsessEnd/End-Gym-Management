-- ========================================================
-- HỌC PHẦN: PHÂN TÍCH THIẾT KẾ HỆ THỐNG THÔNG TIN
-- ĐỀ TÀI 20: WEBSITE QUẢN LÝ PHÒNG GYM
-- FILE: 02_seed_data.sql
-- MÔI TRƯỜNG: Microsoft SQL Server (SSMS 22)
-- ========================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

USE GymManagementDB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Xóa dữ liệu cũ theo thứ tự
DELETE FROM training_bookings;
DELETE FROM trainer_slots;
DELETE FROM checkins;
DELETE FROM memberships;
DELETE FROM membership_plans;
DELETE FROM users;

-- Reset identity về 0 để bản ghi đầu tiên bắt đầu từ 1
DBCC CHECKIDENT ('users', RESEED, 0);
DBCC CHECKIDENT ('membership_plans', RESEED, 0);
DBCC CHECKIDENT ('memberships', RESEED, 0);
DBCC CHECKIDENT ('checkins', RESEED, 0);
DBCC CHECKIDENT ('trainer_slots', RESEED, 0);
DBCC CHECKIDENT ('training_bookings', RESEED, 0);
GO

-- --------------------------------------------------------
-- 1. NẠP USERS (8 tài khoản - Mật khẩu đều là: 123456)
-- Hash bcrypt 10 rounds: $2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G
-- --------------------------------------------------------
INSERT INTO users (full_name, email, phone, password_hash, role, is_active) VALUES
(N'Quản Trị Viên Hệ Thống', 'admin@gym.com', '0901000001', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'admin', 1),
(N'HLV Nguyễn Văn Thể', 'trainer.the@gym.com', '0901000002', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'trainer', 1),
(N'HLV Trần Thị Luyện', 'trainer.luyen@gym.com', '0901000003', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'trainer', 1),
(N'Hội viên Lê Thái Anh', 'thaianh@gmail.com', '0901000004', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Phạm Minh Hoàng', 'hoang.pm@gmail.com', '0901000005', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Vũ Hải Đăng', 'dang.vh@gmail.com', '0901000006', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Hoàng Ngọc Mai', 'mai.hn@gmail.com', '0901000007', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Đỗ Thanh Tùng', 'tung.dt@gmail.com', '0901000008', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1);
GO

-- --------------------------------------------------------
-- 2. NẠP MEMBERSHIP_PLANS (5 gói tập chính)
-- --------------------------------------------------------
INSERT INTO membership_plans (name, duration_days, price, description, is_active) VALUES
(N'Gói Trải Nghiệm 1 Tháng', 30, 450000.00, N'Tập luyện tự do toàn bộ máy tập trong 30 ngày', 1),
(N'Gói Tiêu Chuẩn 3 Tháng', 90, 1200000.00, N'Tiết kiệm 15%, tặng kèm 1 buổi tư vấn thể lực', 1),
(N'Gói Nâng Cao 6 Tháng', 180, 2100000.00, N'Sử dụng phòng tắm nước nóng, tủ locker riêng', 1),
(N'Gói VIP Toàn Niên 1 Năm', 365, 3800000.00, N'Đầy đủ tiện ích, tặng 3 buổi tập cùng Huấn luyện viên', 1),
(N'Gói Sinh Viên Siêu Rẻ', 30, 299000.00, N'Ưu đãi khung giờ 08:00 - 16:00 hằng ngày', 1);
GO

-- --------------------------------------------------------
-- 3. NẠP TRAINER_SLOTS (16 khung giờ của 2 Huấn luyện viên)
-- --------------------------------------------------------
-- HLV 1: id=2 (Nguyễn Văn Thể)
INSERT INTO trainer_slots (trainer_id, starts_at, ends_at, is_available) VALUES
(2, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(hour, 14, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(day, 1, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 0),
(2, DATEADD(day, 1, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1);

-- HLV 2: id=3 (Trần Thị Luyện)
INSERT INTO trainer_slots (trainer_id, starts_at, ends_at, is_available) VALUES
(3, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 20, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(day, 1, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1),
(3, DATEADD(day, 1, DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 0);
GO

-- --------------------------------------------------------
-- 4. NẠP MEMBERSHIPS (9 gói đăng ký - Có cả gói sắp hết hạn cho Báo cáo 1)
-- --------------------------------------------------------
INSERT INTO memberships (user_id, membership_plan_id, starts_on, ends_on, paid_amount, status) VALUES
-- Lê Thái Anh (id=4): Gói 1 năm, còn hạn dài
(4, 4, DATEADD(day, -60, CAST(GETDATE() AS DATE)), DATEADD(day, 305, CAST(GETDATE() AS DATE)), 3800000.00, 'active'),

-- Phạm Minh Hoàng (id=5): Gói 1 tháng SẮP HẾT HẠN TRONG 3 NGÀY (Phục vụ Báo cáo 1)
(5, 1, DATEADD(day, -27, CAST(GETDATE() AS DATE)), DATEADD(day, 3, CAST(GETDATE() AS DATE)), 450000.00, 'active'),

-- Vũ Hải Đăng (id=6): Gói 3 tháng SẮP HẾT HẠN TRONG 6 NGÀY (Phục vụ Báo cáo 1)
(6, 2, DATEADD(day, -84, CAST(GETDATE() AS DATE)), DATEADD(day, 6, CAST(GETDATE() AS DATE)), 1200000.00, 'active'),

-- Hoàng Ngọc Mai (id=7): Gói 6 tháng, còn hạn
(7, 3, DATEADD(day, -30, CAST(GETDATE() AS DATE)), DATEADD(day, 150, CAST(GETDATE() AS DATE)), 2100000.00, 'active'),

-- Đỗ Thanh Tùng (id=8): Gói 1 tháng ĐÃ HẾT HẠN (Dùng cho Test case từ chối check-in)
(8, 5, DATEADD(day, -45, CAST(GETDATE() AS DATE)), DATEADD(day, -15, CAST(GETDATE() AS DATE)), 299000.00, 'expired'),

-- Dữ liệu gia hạn nối tiếp của Thái Anh (id=4, gói tiếp nối không chồng lấn ngày)
(4, 4, DATEADD(day, 306, CAST(GETDATE() AS DATE)), DATEADD(day, 671, CAST(GETDATE() AS DATE)), 3800000.00, 'active'),

-- Dữ liệu lịch sử các tháng trước để phục vụ Báo cáo Doanh thu (Báo cáo 2)
(5, 2, '2026-07-01', '2026-09-29', 1200000.00, 'expired'),
(6, 1, '2026-08-10', '2026-09-09', 450000.00, 'expired'),
(7, 1, '2026-08-15', '2026-09-14', 450000.00, 'expired');
GO

-- --------------------------------------------------------
-- 5. NẠP CHECKINS (19 lượt vào phòng tập - Phục vụ Báo cáo 3)
-- --------------------------------------------------------
INSERT INTO checkins (membership_id, checked_at) VALUES
(1, DATEADD(day, -10, DATEADD(hour, 6, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -9, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -8, DATEADD(hour, 6, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -7, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -5, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -3, DATEADD(hour, 6, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(day, -1, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(1, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))),

(2, DATEADD(day, -6, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(2, DATEADD(day, -4, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(2, DATEADD(day, -2, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(2, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))),

(3, DATEADD(day, -5, DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(3, DATEADD(day, -3, DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(3, DATEADD(day, -1, DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),

(4, DATEADD(day, -4, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(4, DATEADD(day, -2, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(4, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))),

(7, '2026-07-05 08:30:00');
GO

-- --------------------------------------------------------
-- 6. NẠP TRAINING_BOOKINGS (10 lượt đặt lịch HLV)
-- --------------------------------------------------------
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

INSERT INTO training_bookings (member_id, trainer_slot_id, status) VALUES
-- Các lượt đặt đang hiệu lực (khớp với is_available = 0 trong slots)
(4, 1, 'confirmed'),
(5, 3, 'confirmed'),
(6, 5, 'confirmed'),
(4, 7, 'confirmed'),
(7, 9, 'confirmed'),
(4, 11, 'confirmed'),
(5, 13, 'confirmed'),
(6, 16, 'confirmed'),

-- Lượt đặt đã hoàn tất trong quá khứ
(4, 2, 'completed'),

-- Lượt đặt đã hủy (Minh chứng cho việc slot 4 vẫn có thể được đặt lại nhờ Filtered Index)
(5, 4, 'cancelled');
GO

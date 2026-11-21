-- ========================================================
-- HỌC PHẦN: PHÂN TÍCH THIẾT KẾ HỆ THỐNG THÔNG TIN
-- ĐỀ TÀI 20: WEBSITE QUẢN LÝ PHÒNG GYM
-- FILE: setup_all.sql (Chạy toàn bộ Schema và Seed Data)
-- MÔI TRƯỜNG: Microsoft SQL Server (SSMS 22)
-- ========================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'GymManagementDB')
BEGIN
    CREATE DATABASE GymManagementDB;
END
GO

USE GymManagementDB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. XÓA BẢNG CŨ NẾU CÓ
IF OBJECT_ID('training_bookings', 'U') IS NOT NULL DROP TABLE training_bookings;
IF OBJECT_ID('trainer_slots', 'U') IS NOT NULL DROP TABLE trainer_slots;
IF OBJECT_ID('checkins', 'U') IS NOT NULL DROP TABLE checkins;
IF OBJECT_ID('memberships', 'U') IS NOT NULL DROP TABLE memberships;
IF OBJECT_ID('membership_plans', 'U') IS NOT NULL DROP TABLE membership_plans;
IF OBJECT_ID('users', 'U') IS NOT NULL DROP TABLE users;
GO

-- 2. TẠO CẤU TRÚC 6 BẢNG
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL CONSTRAINT UQ_users_email UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CONSTRAINT CK_users_role CHECK (role IN ('admin', 'trainer', 'member')),
    is_active BIT NOT NULL CONSTRAINT DF_users_is_active DEFAULT 1,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_users_created_at DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NULL
);
GO

CREATE TABLE membership_plans (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    duration_days INT NOT NULL CONSTRAINT CK_plans_duration CHECK (duration_days > 0),
    price DECIMAL(12,2) NOT NULL CONSTRAINT CK_plans_price CHECK (price >= 0),
    description NVARCHAR(255) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_plans_is_active DEFAULT 1,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_plans_created_at DEFAULT SYSDATETIME()
);
GO

CREATE TABLE memberships (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    membership_plan_id INT NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    paid_amount DECIMAL(12,2) NOT NULL CONSTRAINT CK_memberships_paid CHECK (paid_amount >= 0),
    status VARCHAR(20) NOT NULL CONSTRAINT DF_memberships_status DEFAULT 'active' 
        CONSTRAINT CK_memberships_status CHECK (status IN ('active', 'expired', 'cancelled')),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_memberships_created_at DEFAULT SYSDATETIME(),
    
    CONSTRAINT FK_memberships_users FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT FK_memberships_plans FOREIGN KEY (membership_plan_id) REFERENCES membership_plans(id),
    CONSTRAINT CK_memberships_dates CHECK (ends_on >= starts_on)
);
GO

CREATE TABLE checkins (
    id INT IDENTITY(1,1) PRIMARY KEY,
    membership_id INT NOT NULL,
    checked_at DATETIME2 NOT NULL CONSTRAINT DF_checkins_checked_at DEFAULT SYSDATETIME(),
    
    CONSTRAINT FK_checkins_memberships FOREIGN KEY (membership_id) REFERENCES memberships(id)
);
GO

CREATE TABLE trainer_slots (
    id INT IDENTITY(1,1) PRIMARY KEY,
    trainer_id INT NOT NULL,
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    is_available BIT NOT NULL CONSTRAINT DF_slots_available DEFAULT 1,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_slots_created_at DEFAULT SYSDATETIME(),
    
    CONSTRAINT FK_trainer_slots_users FOREIGN KEY (trainer_id) REFERENCES users(id),
    CONSTRAINT CK_trainer_slots_time CHECK (ends_at > starts_at)
);
GO

CREATE TABLE training_bookings (
    id INT IDENTITY(1,1) PRIMARY KEY,
    member_id INT NOT NULL,
    trainer_slot_id INT NOT NULL,
    status VARCHAR(20) NOT NULL CONSTRAINT DF_bookings_status DEFAULT 'confirmed'
        CONSTRAINT CK_bookings_status CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_bookings_created_at DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NULL,
    
    CONSTRAINT FK_bookings_member FOREIGN KEY (member_id) REFERENCES users(id),
    CONSTRAINT FK_bookings_slot FOREIGN KEY (trainer_slot_id) REFERENCES trainer_slots(id)
);
GO

-- ========================================================
-- 3. CHỈ MỤC (INDEXES) & RÀNG BUỘC DUY NHẤT CÓ ĐIỀU KIỆN
-- ========================================================

-- [CẤU HÌNH BẮT BUỘC]: Bật chuẩn ANSI để SQL Server cho phép tạo Filtered Index.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. FILTERED UNIQUE INDEX (CHỐNG TRÙNG LỊCH HLV / RACE CONDITION)
-- Khóa duy nhất chỉ áp dụng khi status là 'pending' hoặc 'confirmed'.
-- Tự động giải phóng khung giờ khi buổi tập bị 'cancelled' để người khác đặt lại.
CREATE UNIQUE NONCLUSTERED INDEX UQ_bookings_active_slot
ON training_bookings(trainer_slot_id)
WHERE status IN ('pending', 'confirmed');
GO

-- 2. CÁC CHỈ MỤC TỐI ƯU TÌM KIẾM & 3 BÁO CÁO THỐNG KÊ
-- Phục vụ tìm kiếm nhanh khi Đăng nhập:
CREATE NONCLUSTERED INDEX IX_users_email ON users(email);

-- Phục vụ kiểm tra trạng thái thẻ hội viên:
CREATE NONCLUSTERED INDEX IX_memberships_user_status ON memberships(user_id, status);

-- Phục vụ Báo cáo 1 (Lọc hội viên sắp hết hạn trong 7 ngày):
CREATE NONCLUSTERED INDEX IX_memberships_ends_on ON memberships(ends_on, status);

-- Phục vụ Báo cáo 3 (Thống kê lượt vào theo ngày và theo giờ):
CREATE NONCLUSTERED INDEX IX_checkins_membership_time ON checkins(membership_id, checked_at);

-- Phục vụ lọc lịch làm việc còn trống của HLV:
CREATE NONCLUSTERED INDEX IX_trainer_slots_trainer_time ON trainer_slots(trainer_id, starts_at);
GO

-- 4. NẠP DỮ LIỆU MẪU (SEED DATA)
INSERT INTO users (full_name, email, password_hash, role, is_active) VALUES
(N'Quản Trị Viên Hệ Thống', 'admin@gym.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'admin', 1),
(N'HLV Nguyễn Văn Thể', 'trainer.the@gym.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'trainer', 1),
(N'HLV Trần Thị Luyện', 'trainer.luyen@gym.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'trainer', 1),
(N'Hội viên Lê Thái Anh', 'thaianh@gmail.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Phạm Minh Hoàng', 'hoang.pm@gmail.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Vũ Hải Đăng', 'dang.vh@gmail.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Hoàng Ngọc Mai', 'mai.hn@gmail.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1),
(N'Hội viên Đỗ Thanh Tùng', 'tung.dt@gmail.com', '$2a$10$1pyJoPeuE9OOtWUy5VZSn.0MuERRvNHdxzvTWQoPb5Lk4cSOQch3G', 'member', 1);
GO

INSERT INTO membership_plans (name, duration_days, price, description, is_active) VALUES
(N'Gói Trải Nghiệm 1 Tháng', 30, 450000.00, N'Tập luyện tự do toàn bộ máy tập trong 30 ngày', 1),
(N'Gói Tiêu Chuẩn 3 Tháng', 90, 1200000.00, N'Tiết kiệm 15%, tặng kèm 1 buổi tư vấn thể lực', 1),
(N'Gói Nâng Cao 6 Tháng', 180, 2100000.00, N'Sử dụng phòng tắm nước nóng, tủ locker riêng', 1),
(N'Gói VIP Toàn Niên 1 Năm', 365, 3800000.00, N'Đầy đủ tiện ích, tặng 3 buổi tập cùng Huấn luyện viên', 1),
(N'Gói Sinh Viên Siêu Rẻ', 30, 299000.00, N'Ưu đãi khung giờ 08:00 - 16:00 hằng ngày', 1);
GO

INSERT INTO trainer_slots (trainer_id, starts_at, ends_at, is_available) VALUES
(2, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(hour, 14, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(2, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(2, DATEADD(day, 1, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 0),
(2, DATEADD(day, 1, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1),
(3, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(hour, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 0),
(3, DATEADD(hour, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(hour, 20, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), 1),
(3, DATEADD(day, 1, DATEADD(hour, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1),
(3, DATEADD(day, 1, DATEADD(hour, 16, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(day, 1, DATEADD(hour, 17, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 0);
GO

INSERT INTO memberships (user_id, membership_plan_id, starts_on, ends_on, paid_amount, status) VALUES
(4, 4, DATEADD(day, -60, CAST(GETDATE() AS DATE)), DATEADD(day, 305, CAST(GETDATE() AS DATE)), 3800000.00, 'active'),
(5, 1, DATEADD(day, -27, CAST(GETDATE() AS DATE)), DATEADD(day, 3, CAST(GETDATE() AS DATE)), 450000.00, 'active'),
(6, 2, DATEADD(day, -84, CAST(GETDATE() AS DATE)), DATEADD(day, 6, CAST(GETDATE() AS DATE)), 1200000.00, 'active'),
(7, 3, DATEADD(day, -30, CAST(GETDATE() AS DATE)), DATEADD(day, 150, CAST(GETDATE() AS DATE)), 2100000.00, 'active'),
(8, 5, DATEADD(day, -45, CAST(GETDATE() AS DATE)), DATEADD(day, -15, CAST(GETDATE() AS DATE)), 299000.00, 'expired'),
(4, 4, DATEADD(day, 306, CAST(GETDATE() AS DATE)), DATEADD(day, 671, CAST(GETDATE() AS DATE)), 3800000.00, 'active'),
(5, 2, '2026-07-01', '2026-09-29', 1200000.00, 'expired'),
(6, 1, '2026-08-10', '2026-09-09', 450000.00, 'expired'),
(7, 1, '2026-08-15', '2026-09-14', 450000.00, 'expired');
GO

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

INSERT INTO training_bookings (member_id, trainer_slot_id, status) VALUES
(4, 1, 'confirmed'),
(5, 3, 'confirmed'),
(6, 5, 'confirmed'),
(4, 7, 'confirmed'),
(7, 9, 'confirmed'),
(4, 11, 'confirmed'),
(5, 13, 'confirmed'),
(6, 16, 'confirmed'),
(4, 2, 'completed'),
(5, 4, 'cancelled');
GO

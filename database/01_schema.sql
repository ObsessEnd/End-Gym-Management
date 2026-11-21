-- ========================================================
-- HỌC PHẦN: PHÂN TÍCH THIẾT KẾ HỆ THỐNG THÔNG TIN
-- ĐỀ TÀI 20: WEBSITE QUẢN LÝ PHÒNG GYM
-- FILE: 01_schema.sql
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

-- Xóa bảng theo đúng thứ tự phụ thuộc khóa ngoại nếu chạy lại script
IF OBJECT_ID('training_bookings', 'U') IS NOT NULL DROP TABLE training_bookings;
IF OBJECT_ID('trainer_slots', 'U') IS NOT NULL DROP TABLE trainer_slots;
IF OBJECT_ID('checkins', 'U') IS NOT NULL DROP TABLE checkins;
IF OBJECT_ID('memberships', 'U') IS NOT NULL DROP TABLE memberships;
IF OBJECT_ID('membership_plans', 'U') IS NOT NULL DROP TABLE membership_plans;
IF OBJECT_ID('users', 'U') IS NOT NULL DROP TABLE users;
GO

-- --------------------------------------------------------
-- 1. BẢNG users (Tài khoản dùng chung: Admin, Trainer, Member)
-- --------------------------------------------------------
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL CONSTRAINT UQ_users_email UNIQUE,
    phone VARCHAR(15) NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CONSTRAINT CK_users_role CHECK (role IN ('admin', 'trainer', 'member')),
    is_active BIT NOT NULL CONSTRAINT DF_users_is_active DEFAULT 1,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_users_created_at DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NULL
);
GO

-- --------------------------------------------------------
-- 2. BẢNG membership_plans (Gói tập phòng gym)
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- 3. BẢNG memberships (Đăng ký & gia hạn gói tập)
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- 4. BẢNG checkins (Lượt vào phòng tập)
-- --------------------------------------------------------
CREATE TABLE checkins (
    id INT IDENTITY(1,1) PRIMARY KEY,
    membership_id INT NOT NULL,
    checked_at DATETIME2 NOT NULL CONSTRAINT DF_checkins_checked_at DEFAULT SYSDATETIME(),
    
    CONSTRAINT FK_checkins_memberships FOREIGN KEY (membership_id) REFERENCES memberships(id)
);
GO

-- --------------------------------------------------------
-- 5. BẢNG trainer_slots (Khung giờ làm việc của Huấn luyện viên)
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- 6. BẢNG training_bookings (Đặt lịch tập cá nhân)
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- CÁC CHỈ MỤC (INDEXES) & RÀNG BUỘC DUY NHẤT CÓ ĐIỀU KIỆN
-- --------------------------------------------------------

-- [CẤU HÌNH BẮT BUỘC]: Bật chuẩn ANSI để SQL Server cho phép tạo Filtered Index.
-- ANSI_NULLS ON: Tuân thủ chuẩn so sánh giá trị NULL.
-- QUOTED_IDENTIFIER ON: Cho phép định danh tên bảng/cột chuẩn xác, tránh lỗi Msg 1934.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ========================================================
-- 1. FILTERED UNIQUE INDEX (CHỐNG TRÙNG LỊCH HLV / RACE CONDITION)
-- ========================================================
-- [Ý NGHĨA NGHIỆP VỤ]: 
-- - Khóa duy nhất (UNIQUE) chỉ áp dụng khi status là 'pending' (chờ duyệt) hoặc 'confirmed' (đã chốt).
-- - Đảm bảo tại một thời điểm, một khung giờ (trainer_slot_id) chỉ có TỐI ĐA 1 lượt đặt có hiệu lực.
-- - Khi lượt đặt bị hủy (status = 'cancelled') hoặc đã hoàn thành ('completed'), khung giờ sẽ 
--   tự động được giải phóng khỏi bộ lọc để người khác có thể đặt lại ngay lập tức mà không bị lỗi trùng lặp.
CREATE UNIQUE NONCLUSTERED INDEX UQ_bookings_active_slot
ON training_bookings(trainer_slot_id)
WHERE status IN ('pending', 'confirmed');
GO

-- ========================================================
-- 2. CÁC CHỈ MỤC NON-CLUSTERED TỐI ƯU TÌM KIẾM & 3 BÁO CÁO THỐNG KÊ
-- ========================================================

-- [PHỤC VỤ ĐĂNG NHẬP]: Tăng tốc độ tìm kiếm tài khoản theo email đạt O(log N), tránh quét toàn bộ bảng (Table Scan).
CREATE NONCLUSTERED INDEX IX_users_email 
ON users(email);

-- [PHỤC VỤ CHECK THẺ HỘI VIÊN]: Tìm nhanh các gói tập đang hoạt động (active) của một hội viên cụ thể.
CREATE NONCLUSTERED INDEX IX_memberships_user_status 
ON memberships(user_id, status);

-- [PHỤC VỤ BÁO CÁO 1]: Tối ưu hóa truy vấn lọc danh sách hội viên sắp hết hạn trong 7 ngày tới (ends_on BETWEEN today AND today + 7).
CREATE NONCLUSTERED INDEX IX_memberships_ends_on 
ON memberships(ends_on, status);

-- [PHỤC VỤ BÁO CÁO 3]: Tối ưu hóa câu lệnh đếm lượt vào phòng tập (COUNT) gom nhóm theo ngày và theo khung giờ cao điểm (checked_at).
CREATE NONCLUSTERED INDEX IX_checkins_membership_time 
ON checkins(membership_id, checked_at);

-- [PHỤC VỤ ĐẶT LỊCH HLV]: Tăng tốc độ lọc các khung giờ làm việc còn trống của một huấn luyện viên cụ thể theo ngày.
CREATE NONCLUSTERED INDEX IX_trainer_slots_trainer_time 
ON trainer_slots(trainer_id, starts_at);
GO

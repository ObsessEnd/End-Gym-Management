const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config(); // Nạp các biến môi trường từ file .env

const { poolPromise } = require('./config/db'); // Nạp Connection Pool kết nối SQL Server

// Nạp các router (File nào đã tạo thì require, file nào chưa tạo thì // đóng lại)
const authRoutes = require('./routes/auth');
// const plansRoutes = require('./routes/plans');
// const membershipsRoutes = require('./routes/memberships');
// const checkinsRoutes = require('./routes/checkins');
// const trainerSlotsRoutes = require('./routes/trainer-slots');
// const bookingsRoutes = require('./routes/bookings');
// const reportsRoutes = require('./routes/reports');

const app = express();
const PORT = process.env.PORT || 3000;

// 1. CÁC MIDDLEWARE CƠ BẢN BẮT BUỘC
app.use(cors()); // Cho phép trình duyệt gọi API giữa các cổng mạng
app.use(express.json()); // Đọc dữ liệu gửi lên dưới dạng JSON trong req.body
app.use(express.urlencoded({ extended: true })); // Đọc dữ liệu gửi lên từ form HTML

// Phục vụ giao diện tĩnh (HTML/CSS/JS) từ thư mục public
app.use(express.static(path.join(__dirname, 'public')));

// 2. ĐĂNG KÝ CÁC ROUTE API CHUẨN RESTFUL
app.use('/api/auth', authRoutes); // Tuyến đường Đăng ký, Đăng nhập, Hồ sơ cá nhân

// (Chặng nào tạo xong file thì ta chỉ cần mở // của dòng đó ra)
// app.use('/api/plans', plansRoutes);
// app.use('/api/memberships', membershipsRoutes);
// app.use('/api/checkins', checkinsRoutes);
// app.use('/api/trainer-slots', trainerSlotsRoutes);
// app.use('/api/bookings', bookingsRoutes);
// app.use('/api/reports', reportsRoutes);

// 3. ROUTE MẶC ĐỊNH
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'), (err) => {
    if (err) {
      // Nếu chưa có file login.html ở Chặng 1, hiển thị thông báo trạng thái server
      res.json({
        success: true,
        message: '🚀 Gym Management API Server đang hoạt động tốt trên cổng ' + PORT,
        auth_endpoints: ['POST /api/auth/register', 'POST /api/auth/login', 'GET /api/auth/profile'],
      });
    }
  });
});

// 4. XỬ LÝ LỖI 404 KHI GỌI SAI API (Trong Express 5 dùng prefix '/api' thay cho '/api/*')
app.use('/api', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Không tìm thấy API yêu cầu (404 Not Found)',
  });
});

// 5. MIDDLEWARE XỬ LÝ LỖI TOÀN CỤC (GLOBAL ERROR HANDLER)
app.use((err, req, res, next) => {
  console.error('Lỗi hệ thống chưa bắt:', err);
  res.status(500).json({
    success: false,
    message: 'Đã xảy ra lỗi trên máy chủ',
    error: err.message,
  });
});

// 6. KHỞI ĐỘNG SERVER SAU KHI KẾT NỐI CSDL THÀNH CÔNG
async function startServer() {
  try {
    await poolPromise; // Đảm bảo kết nối SQL Server thông suốt trước khi mở cổng
    app.listen(PORT, () => {
      console.log(`=======================================================`);
      console.log(`🚀 Gym Management Backend đang chạy tại: http://localhost:${PORT}`);
      console.log(`🔑 Sẵn sàng nhận yêu cầu API tại: http://localhost:${PORT}/api/auth`);
      console.log(`=======================================================`);
    });
  } catch (err) {
    console.error('Không thể khởi động server do lỗi kết nối CSDL:', err);
  }
}

startServer();

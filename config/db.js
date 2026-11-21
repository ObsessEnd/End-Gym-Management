const sql = require('mssql');
require('dotenv').config();

// Cấu hình thông số kết nối lấy từ file môi trường .env
const config = {
  user: process.env.DB_USER || 'gym_user',
  password: process.env.DB_PASSWORD || 'GymApp@2026',
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 1433,
  database: process.env.DB_NAME || 'GymManagementDB',
  options: {
    encrypt: false,                // Đặt false khi chạy SQL Server nội bộ trên máy
    trustServerCertificate: true,  // Bỏ qua chứng chỉ SSL tự ký
    enableArithAbort: true,
  },
  // Cấu hình Connection Pool (Nhóm kết nối dùng chung)
  pool: {
    max: 10,                       // Tối đa 10 kết nối đồng thời
    min: 0,                        // Khi rảnh rỗi giải phóng về 0 để tiết kiệm RAM
    idleTimeoutMillis: 30000,      // Kết nối không dùng sau 30 giây sẽ tự đóng
  },
};

// Khởi tạo Connection Pool Promise dùng chung cho toàn bộ dự án
const poolPromise = new sql.ConnectionPool(config)
  .connect()
  .then((pool) => {
    console.log('✅ Đã kết nối thành công tới SQL Server: ' + config.database);
    return pool;
  })
  .catch((err) => {
    console.error('❌ Lỗi kết nối SQL Server:', err.message);
    process.exit(1);
  });

module.exports = {
  sql,
  poolPromise,
};
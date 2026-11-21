const jwt = require('jsonwebtoken');
require('dotenv').config();

// Khóa bí mật lấy từ file .env để giải mã và kiểm tra chữ ký Token
const JWT_SECRET = process.env.JWT_SECRET || 'gym_secret_key_2026_thai_anh';

/**
 * 1. Middleware xác thực JSON Web Token (JWT)
 * Kiểm tra xem người dùng đã đăng nhập và gửi Token hợp lệ chưa
 */
function authenticateToken(req, res, next) {
  // Lấy chuỗi header Authorization (Định dạng chuẩn: Bearer <TOKEN>)
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  // Nếu không gửi Token -> Báo lỗi 401 (Chưa đăng nhập)
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Vui lòng đăng nhập để tiếp tục (Thiếu mã xác thực Token)',
    });
  }

  // Xác thực chữ ký số của Token bằng khóa bí mật
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn',
      });
    }
    // Gắn thông tin người dùng đã giải mã vào req.user để các controller phía sau dùng
    req.user = user;
    next(); // Cho phép đi tiếp vào route kế tiếp
  });
}

/**
 * 2. Middleware phân quyền theo vai trò (Role-Based Access Control)
 * @param  {...string} allowedRoles Danh sách các quyền được phép: 'admin', 'trainer', 'member'
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    // Nếu chưa qua bước xác thực hoặc thiếu vai trò
    if (!req.user || !req.user.role) {
      return res.status(401).json({
        success: false,
        message: 'Yêu cầu xác thực tài khoản trước khi thực hiện thao tác',
      });
    }

    // Nếu vai trò của tài khoản không nằm trong danh sách được cấp phép -> Chặn lại với lỗi 403
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Quyền truy cập bị từ chối! Chức năng này chỉ dành cho vai trò: ${allowedRoles.join(', ')}`,
      });
    }

    next(); // Hợp lệ, cho phép tiếp tục
  };
}

module.exports = {
  authenticateToken,
  requireRole,
};
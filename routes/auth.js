const express = require('express'); // Framework web dựng máy chủ và API RESTful
const router = express.Router();     // Bộ định tuyến nhánh, giúp tách module code gọn gàng
const bcrypt = require('bcryptjs');  // Thuật toán băm mật khẩu một chiều (10 rounds Salt)
const jwt = require('jsonwebtoken'); // Thư viện tạo và xác thực mã Token JWT phiên đăng nhập
const { sql, poolPromise } = require('../config/db');           // Kết nối Connection Pool tới SQL Server
const { authenticateToken } = require('../middlewares/auth');   // Middleware gác cổng kiểm tra đăng nhập

// Khóa bí mật và thời hạn sống của Token (7 ngày)
const JWT_SECRET = process.env.JWT_SECRET || 'gym_secret_key_2026_thai_anh';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

// Quy tắc kiểm tra SĐT Việt Nam: đúng 10 chữ số, bắt đầu bằng số 0
const PHONE_REGEX = /^0\d{9}$/;

/**
 * 1. ĐĂNG KÝ HỘI VIÊN MỚI (POST /api/auth/register)
 * Nghiệp vụ: Kiểm tra dữ liệu + SĐT regex, băm mật khẩu bcrypt, cố định role = 'member'
 */
router.post('/register', async (req, res) => {
  try {
    const { full_name, email, phone, password } = req.body || {};

    // Kiểm tra thông tin bắt buộc trước khi chạm vào Database (Fail-Fast)
    if (!full_name || !email || !phone || !password || password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Họ tên, email, số điện thoại là bắt buộc và mật khẩu phải từ 6 ký tự trở lên',
      });
    }

    const cleanPhone = String(phone).trim();
    if (!PHONE_REGEX.test(cleanPhone)) {
      return res.status(400).json({
        success: false,
        message: 'Số điện thoại không hợp lệ (phải gồm đúng 10 chữ số và bắt đầu bằng số 0)',
      });
    }

    const pool = await poolPromise; // Chờ mượn 1 kết nối từ Connection Pool

    // Kiểm tra trùng email (dùng .input() để chống 100% lỗi SQL Injection)
    const checkEmail = await pool.request()
      .input('email', sql.VarChar, email.trim().toLowerCase())
      .query('SELECT id FROM users WHERE email = @email');

    if (checkEmail.recordset.length > 0) {
      return res.status(400).json({ success: false, message: 'Email này đã tồn tại trong hệ thống' });
    }

    // Băm mật khẩu với 10 vòng Salt ngẫu nhiên (không thể dịch ngược)
    const password_hash = await bcrypt.hash(password, 10);

    // Chèn tài khoản mới (gán cứng role = 'member' để chống leo thang đặc quyền)
    const result = await pool.request()
      .input('full_name', sql.NVarChar, full_name.trim())
      .input('email', sql.VarChar, email.trim().toLowerCase())
      .input('phone', sql.VarChar(15), cleanPhone)
      .input('password_hash', sql.VarChar, password_hash)
      .input('role', sql.VarChar, 'member')
      .input('is_active', sql.Bit, 1)
      .query(`
        INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
        OUTPUT INSERTED.id, INSERTED.full_name, INSERTED.email, INSERTED.phone, INSERTED.role, INSERTED.created_at
        VALUES (@full_name, @email, @phone, @password_hash, @role, @is_active)
      `);

    return res.status(201).json({
      success: true,
      message: 'Đăng ký tài khoản hội viên thành công!',
      data: result.recordset[0],
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ khi đăng ký', error: error.message });
  }
});

/**
 * 2. ĐĂNG NHẬP HỆ THỐNG (POST /api/auth/login)
 * Nghiệp vụ: So khớp bcrypt, kiểm tra is_active, ký JWT và trả về user (kèm phone, bỏ password_hash)
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ email và mật khẩu' });
    }

    const pool = await poolPromise;
    const result = await pool.request()
      .input('email', sql.VarChar, email.trim().toLowerCase())
      .query('SELECT * FROM users WHERE email = @email');

    if (result.recordset.length === 0) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không chính xác' });
    }

    const user = result.recordset[0];

    // Tài khoản bị Admin khóa (is_active = 0) thì chặn lại với mã 403
    if (!user.is_active) {
      return res.status(403).json({ success: false, message: 'Tài khoản của bạn đã bị vô hiệu hóa' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không chính xác' });
    }

    // Ký số sinh JWT Token chứa thông tin định danh cơ bản
    const token = jwt.sign(
      { id: user.id, email: user.email, full_name: user.full_name, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    // Lọc bỏ password_hash, trả thêm phone để đồng bộ với localStorage ở Frontend
    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công',
      data: {
        token,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          phone: user.phone || null,
          role: user.role,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ khi đăng nhập', error: error.message });
  }
});

/**
 * 3. XEM HỒ SƠ CÁ NHÂN (GET /api/auth/profile)
 * Bảo vệ: Phải qua authenticateToken trước, lấy req.user.id từ Token (chống xem trộm ID người khác)
 */
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input('id', sql.Int, req.user.id)
      .query('SELECT id, full_name, email, phone, role, is_active, created_at FROM users WHERE id = @id');

    if (result.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
    }

    return res.status(200).json({ success: true, data: result.recordset[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ khi lấy hồ sơ' });
  }
});

/**
 * 4. CẬP NHẬT HỒ SƠ CÁ NHÂN (PUT /api/auth/profile)
 * Nghiệp vụ: Sửa họ tên, SĐT (đúng regex /^0\d{9}$/) và mật khẩu mới (nếu nhập >= 6 ký tự)
 */
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { full_name, phone, password } = req.body || {};
    if (!full_name || !full_name.trim()) {
      return res.status(400).json({ success: false, message: 'Họ tên không được để trống' });
    }

    const pool = await poolPromise;
    const request = pool.request()
      .input('id', sql.Int, req.user.id)
      .input('full_name', sql.NVarChar, full_name.trim());

    let query = 'UPDATE users SET full_name = @full_name, updated_at = SYSDATETIME()';

    // Nếu người dùng truyền trường phone -> kiểm tra bắt buộc đúng 10 số bắt đầu bằng 0
    if (phone !== undefined) {
      const cleanPhone = String(phone).trim();
      if (!PHONE_REGEX.test(cleanPhone)) {
        return res.status(400).json({
          success: false,
          message: 'Số điện thoại không hợp lệ (phải gồm đúng 10 chữ số và bắt đầu bằng số 0)',
        });
      }
      request.input('phone', sql.VarChar(15), cleanPhone);
      query += ', phone = @phone';
    }

    // Nếu có gõ mật khẩu mới thì bắt buộc >= 6 ký tự (tránh bỏ qua âm thầm)
    if (password !== undefined && String(password).trim() !== '') {
      const cleanPassword = String(password).trim();
      if (cleanPassword.length < 6) {
        return res.status(400).json({
          success: false,
          message: 'Mật khẩu mới phải có từ 6 ký tự trở lên',
        });
      }
      const password_hash = await bcrypt.hash(cleanPassword, 10);
      request.input('password_hash', sql.VarChar, password_hash);
      query += ', password_hash = @password_hash';
    }

    query += ' OUTPUT INSERTED.id, INSERTED.full_name, INSERTED.email, INSERTED.phone, INSERTED.role, INSERTED.updated_at WHERE id = @id';

    const result = await request.query(query);
    return res.status(200).json({ success: true, message: 'Cập nhật thành công', data: result.recordset[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi khi cập nhật hồ sơ' });
  }
});

module.exports = router;
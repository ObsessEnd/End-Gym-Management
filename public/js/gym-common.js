/**
 * ============================================================================
 * ENDGYM CORE & ANIMATE-UI MOTION ENGINE (animate-ui.com inspired)
 * - Chống XSS (repos/vibe-check)
 * - 5 Hạng Thẻ Vật Lý 3D Tối Giản Sang Trọng (Apple Card / Centurion style)
 * - Animate-UI Sliding Pill Tabs (Chuyển tab trượt mượt chuẩn Spring Physics)
 * - Animate-UI Staggered Entrance & Cursor Spotlight
 * ============================================================================
 */

// 1. Làm sạch dữ liệu đầu ra chống tấn công XSS
function escapeHtml(unsafe) {
  if (unsafe === null || unsafe === undefined) return '';
  return String(unsafe)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// 2. Định dạng tiền tệ VNĐ
function formatVND(amount) {
  const num = Number(amount) || 0;
  return new Intl.NumberFormat('vi-VN').format(num) + ' đ';
}

// 3. Định dạng ngày chuẩn DD/MM/YYYY
function formatDateVN(dateStr) {
  if (!dateStr) return '---';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return escapeHtml(dateStr);
  return d.toLocaleDateString('vi-VN');
}

// 4. Định dạng ngày giờ HH:mm - DD/MM/YYYY
function formatDateTimeVN(dateStr) {
  if (!dateStr) return '---';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return escapeHtml(dateStr);
  return (
    d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) +
    ' - ' +
    d.toLocaleDateString('vi-VN')
  );
}

// 5. Lấy thông tin người dùng đang đăng nhập
function getGymUser() {
  try {
    const raw = localStorage.getItem('gym_user');
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    localStorage.removeItem('gym_user');
    return null;
  }
}

// 6. Đăng xuất hệ thống
function logoutGym() {
  localStorage.removeItem('gym_token');
  localStorage.removeItem('gym_user');
  window.location.href = '/login.html';
}

// 7. DANH MỤC 5 HẠNG THẺ VẬT LÝ 3D (TỐI GIẢN, THOÁNG ĐÃNG, SANG TRỌNG)
const ENDGYM_CARD_TIERS = {
  rookie: {
    key: 'rookie',
    cssClass: 'tier-rookie',
    shortTag: 'TIER I',
    rankCode: 'TIER I • IRON ROOKIE',
    cardTitle: 'IRON ROOKIE',
    materialName: 'Thép Nhám Gunmetal',
    chipGradient: 'linear-gradient(135deg, #d4d4d8 0%, #52525b 100%)',
    perks: ['Khung giờ 08h–16h', 'Free Weight & Cardio', 'Cổng từ RFID']
  },
  warrior: {
    key: 'warrior',
    cssClass: 'tier-warrior',
    shortTag: 'TIER II',
    rankCode: 'TIER II • STEEL WARRIOR',
    cardTitle: 'STEEL WARRIOR',
    materialName: 'Thép Xước Xanh Cobalt',
    chipGradient: 'linear-gradient(135deg, #bae6fd 0%, #0284c7 100%)',
    perks: ['Full giờ 06h–22h', '120+ Máy Olympic', 'Cộng dồn ngày tập']
  },
  silver: {
    key: 'silver',
    cssClass: 'tier-silver',
    shortTag: 'TIER III',
    rankCode: 'TIER III • SILVER TITAN',
    cardTitle: 'SILVER TITAN',
    materialName: 'Bạc Ánh Kim Chrome',
    chipGradient: 'linear-gradient(135deg, #ffffff 0%, #a1a1aa 100%)',
    perks: ['Full 4 Phân khu + Boxing', '02 lần đo InBody 770', 'Đặt lịch PT 1-on-1']
  },
  crimson: {
    key: 'crimson',
    cssClass: 'tier-crimson',
    shortTag: 'TIER IV',
    rankCode: 'TIER IV • CRIMSON ELITE',
    cardTitle: 'CRIMSON ELITE',
    materialName: 'Sợi Carbon Đỏ Huyết Ngọc',
    chipGradient: 'linear-gradient(135deg, #fda4af 0%, #e11d48 100%)',
    perks: ['Tủ Locker VIP & Sauna', 'Tặng 01 buổi PT', 'Ưu tiên lớp Studio']
  },
  centurion: {
    key: 'centurion',
    cssClass: 'tier-centurion',
    shortTag: 'TIER V • VIP',
    rankCode: 'TIER V • CENTURION 24K',
    cardTitle: 'CENTURION BLACK',
    materialName: 'Thép Đen Obsidian & Vàng 24K',
    chipGradient: 'linear-gradient(135deg, #fde68a 0%, #d97706 100%)',
    perks: ['Đặc quyền 24/7 Toàn CLB', 'Tặng 03 buổi Master PT', 'Khăn & Nước miễn phí']
  }
};

function getEndGymCardTier(planOrObj) {
  if (!planOrObj) return ENDGYM_CARD_TIERS.centurion;
  if (typeof planOrObj === 'string' && ENDGYM_CARD_TIERS[planOrObj]) {
    return ENDGYM_CARD_TIERS[planOrObj];
  }
  const name = String(planOrObj.name || planOrObj.plan_name || '').toUpperCase();
  const days = Number(planOrObj.duration_days) || 0;
  const price = Number(planOrObj.price || planOrObj.paid_amount) || 0;

  if (name.includes('CENTURION') || name.includes('VIP') || name.includes('1 NĂM') || days >= 360 || price >= 3000000) {
    return ENDGYM_CARD_TIERS.centurion;
  }
  if (name.includes('CRIMSON') || name.includes('NÂNG CAO') || name.includes('6 THÁNG') || (days >= 150 && days < 360) || price >= 1800000) {
    return ENDGYM_CARD_TIERS.crimson;
  }
  if (name.includes('SILVER') || name.includes('TIÊU CHUẨN') || name.includes('3 THÁNG') || (days >= 80 && days < 150) || price >= 900000) {
    return ENDGYM_CARD_TIERS.silver;
  }
  if (name.includes('SINH VIÊN') || name.includes('ROOKIE') || (price > 0 && price <= 350000)) {
    return ENDGYM_CARD_TIERS.rookie;
  }
  return ENDGYM_CARD_TIERS.warrior;
}

// Tạo HTML Thẻ Mini Preview thoáng đãng trên mỗi gói tập
function renderMiniTierCardHtml(plan) {
  const tier = getEndGymCardTier(plan);
  return `
    <div class="${tier.cssClass}" style="margin-bottom: 20px;">
      <div class="card-3d-face mini-tier-card" style="position: relative; height: 124px; padding: 16px 20px; border-radius: 14px;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <img src="/assets/endgym-shield-emblem.png" alt="ENDGYM" style="width: 26px; height: 26px; object-fit: contain;" />
            <span style="font-family: 'JetBrains Mono', monospace; font-size: 0.68rem; font-weight: 700; letter-spacing: 0.1em;" class="tier-accent-text">${tier.shortTag}</span>
          </div>
          <span style="width: 30px; height: 21px; border-radius: 4px; background: ${tier.chipGradient}; border: 1px solid rgba(255,255,255,0.45);"></span>
        </div>
        <div style="display: flex; justify-content: space-between; align-items: flex-end;">
          <div>
            <div style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.25rem; font-weight: 900; font-style: italic; color: #fff; letter-spacing: 0.05em;">${tier.cardTitle}</div>
            <div style="font-size: 0.75rem; color: rgba(255,255,255,0.65);">${tier.materialName}</div>
          </div>
          <span style="font-family: 'JetBrains Mono', monospace; font-size: 0.65rem; padding: 3px 8px; border-radius: 99px;" class="tier-pill">3D PASS</span>
        </div>
      </div>
    </div>
  `;
}

// 8. ANIMATE-UI SLIDING PILL TABS ENGINE (Hiệu ứng trượt viên thuốc mượt chuẩn animate-ui.com)
function initAuiTabs(containerSelector = '.aui-tabs') {
  document.querySelectorAll(containerSelector).forEach((tabBar) => {
    let indicator = tabBar.querySelector('.aui-tab-indicator');
    if (!indicator) {
      indicator = document.createElement('div');
      indicator.className = 'aui-tab-indicator';
      tabBar.prepend(indicator);
    }

    const buttons = Array.from(tabBar.querySelectorAll('.aui-tab-btn'));
    const moveIndicator = (activeBtn) => {
      if (!activeBtn) return;
      const barRect = tabBar.getBoundingClientRect();
      const btnRect = activeBtn.getBoundingClientRect();
      indicator.style.width = `${btnRect.width}px`;
      indicator.style.transform = `translateX(${btnRect.left - barRect.left - 5}px)`;
    };

    const currentActive = tabBar.querySelector('.aui-tab-btn.active') || buttons[0];
    setTimeout(() => moveIndicator(currentActive), 30);
    window.addEventListener('resize', () => {
      const act = tabBar.querySelector('.aui-tab-btn.active') || buttons[0];
      moveIndicator(act);
    });

    buttons.forEach((btn) => {
      btn.addEventListener('click', () => {
        buttons.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        moveIndicator(btn);

        const targetId = btn.getAttribute('data-aui-target');
        if (targetId) {
          const group = btn.closest('.aui-tab-system') || document;
          group.querySelectorAll('.aui-tab-panel').forEach((panel) => {
            if (panel.id === targetId) {
              panel.classList.add('active');
            } else {
              panel.classList.remove('active');
            }
          });
        }
      });
    });
  });
}
// 8B. HỆ THỐNG BẢO VỆ TRANG (ROUTE GUARD) & NAVBAR DÙNG CHUNG THEO VAI TRÒ

// Trả về trang mặc định tương ứng với vai trò của tài khoản
function getDefaultHomeByRole(role) {
  if (role === 'admin') return '/admin-plans.html';
  if (role === 'trainer') return '/trainer-portal.html';
  return '/member-portal.html';
}

// Giải mã phần Payload của JWT (không cần gọi Server) để kiểm tra Token đã hết hạn chưa
function isTokenExpired(token) {
  try {
    const parts = String(token).split('.');
    if (parts.length !== 3) return true; // Token sai cấu trúc 3 phần -> coi như hỏng
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const payload = JSON.parse(atob(base64));
    if (!payload.exp) return false;
    return payload.exp * 1000 <= Date.now(); // Quy đổi exp (giây) sang mili-giây để so sánh
  } catch (e) {
    return true;
  }
}

/**
 * Bảo vệ trang: đặt ở đầu script của các trang yêu cầu đăng nhập
 * @param {string[]} allowedRoles - Mảng các vai trò được phép vào trang (VD: ['admin'])
 * @returns {object|null} Trả về object user nếu hợp lệ, ngược lại tự chuyển trang và trả null
 */
function guardPage(allowedRoles = []) {
  const token = localStorage.getItem('gym_token');
  const user = getGymUser();

  // Chưa đăng nhập hoặc Token hết hạn -> xóa rác và đẩy về trang đăng nhập
  if (!token || !user || isTokenExpired(token)) {
    localStorage.removeItem('gym_token');
    localStorage.removeItem('gym_user');
    window.location.replace('/login.html');
    return null;
  }

  // Đã đăng nhập nhưng sai vai trò (VD: Member cố mở trang Admin) -> đẩy về đúng cổng của mình
  if (Array.isArray(allowedRoles) && allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
    window.location.replace(getDefaultHomeByRole(user.role));
    return null;
  }

  return user;
}

/**
 * Tự động vẽ thanh Menu điều hướng chuẩn theo vai trò đang đăng nhập
 * @param {string} activeKey - Khóa trang đang mở để tô sáng viền đỏ (VD: 'home', 'plans', 'member')
 */
function renderNavbar(activeKey = '') {
  const navContainer = document.querySelector('.navbar .nav-links, .navbar .navbar-links');
  if (!navContainer) return;

  const token = localStorage.getItem('gym_token');
  const rawUser = getGymUser();
  const user = token && rawUser && !isTokenExpired(token) ? rawUser : null;
  const role = user ? user.role : 'guest';

  // Bảng cấu hình Menu theo từng vai trò (Lookup Table giúp code gọn, không if/else dài dòng)
  const MENU_BY_ROLE = {
    admin: [
      { key: 'home', href: '/index.html', label: 'Trang chủ' },
      { key: 'plans', href: '/admin-plans.html', label: 'Quản lý Gói' },
      { key: 'memberships', href: '/admin-memberships.html', label: 'Hợp đồng' },
      { key: 'checkin', href: '/checkin.html', label: 'Trạm RFID' },
      { key: 'reports', href: '/admin-reports.html', label: 'Báo cáo' },
      { key: 'profile', href: '/profile.html', label: 'Hồ sơ' },
    ],
    trainer: [
      { key: 'home', href: '/index.html', label: 'Trang chủ' },
      { key: 'trainer', href: '/trainer-portal.html', label: 'Lịch dạy PT' },
      { key: 'pricing', href: '/pricing.html', label: 'Bảng giá' },
      { key: 'profile', href: '/profile.html', label: 'Hồ sơ' },
    ],
    member: [
      { key: 'home', href: '/index.html', label: 'Trang chủ' },
      { key: 'pricing', href: '/pricing.html', label: 'Gói Thẻ VIP' },
      { key: 'member', href: '/member-portal.html', label: 'Thẻ 3D & PT' },
      { key: 'profile', href: '/profile.html', label: 'Hồ sơ' },
    ],
    guest: [
      { key: 'home', href: '/index.html', label: 'Trang chủ' },
      { key: 'pricing', href: '/pricing.html', label: 'Gói Thẻ VIP' },
      { key: 'login', href: '/login.html', label: 'Đăng nhập' },
      { key: 'register', href: '/register.html', label: 'Gia nhập Ngay', isBtn: true },
    ],
  };

  const links = MENU_BY_ROLE[role] || MENU_BY_ROLE.guest;

  const linksHtml = links
    .map((item) => {
      const activeClass = item.key === activeKey ? 'active' : '';
      const extraClass = item.isBtn ? 'btn' : activeClass;
      const inlineStyle = item.isBtn ? 'style="padding: 8px 18px; font-size: 0.92rem;"' : '';
      return `<a href="${item.href}" class="${extraClass}" ${inlineStyle}>${item.label}</a>`;
    })
    .join('');

  // Nếu đã đăng nhập, gắn thêm nhãn tên người dùng (bọc escapeHtml chống XSS) + nút Đăng xuất
  const userHtml = user
    ? `
      <span class="nav-user-badge"><span class="led-dot green"></span><strong>${escapeHtml(user.full_name)}</strong></span>
      <button type="button" class="btn-logout" onclick="logoutGym()">Đăng xuất</button>
    `
    : '';

  navContainer.innerHTML = linksHtml + userHtml;
}
// 9. Khởi tạo toàn cục khi DOM sẵn sàng
document.addEventListener('DOMContentLoaded', () => {
  // 9.1. Favicon
  if (!document.querySelector('link[rel="icon"]')) {
    const link = document.createElement('link');
    link.rel = 'icon';
    link.type = 'image/png';
    link.href = '/assets/favicon.png';
    document.head.appendChild(link);
  }

  // 9.2. Logo Khiên Tạ ENDGYM trên Navbar
  document.querySelectorAll('.nav-brand').forEach((brand) => {
    brand.innerHTML = `
      <img src="/assets/endgym-shield-emblem.png" alt="ENDGYM Shield" class="nav-brand-emblem" />
      <span><span class="word-end">END</span><span class="word-gym">GYM</span></span>
    `;
  });

  // 9.3. Hiệu ứng Cursor Spotlight mượt mà
  document.addEventListener('mousemove', (e) => {
    document.querySelectorAll('.card, .plan-card, .stat-card, .zone-card, .slot-card').forEach((card) => {
      const rect = card.getBoundingClientRect();
      card.style.setProperty('--mouse-x', `${e.clientX - rect.left}px`);
      card.style.setProperty('--mouse-y', `${e.clientY - rect.top}px`);
    });
  });

  // 9.4. Khởi tạo Animate-UI Sliding Tabs
  initAuiTabs();
});

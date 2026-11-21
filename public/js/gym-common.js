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

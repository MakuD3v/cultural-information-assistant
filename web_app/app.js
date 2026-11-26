const API_BASE = 'http://localhost:8000';

let currentUser = null;
let currentTab = 0; // 0: Home, 1: Plan, 2: Ask, 3: Map, 4: Culture, 5: More
let isOffline = false;
let showSteps = true;
let programDay = 3;
let activePlanDay = 3;
let selectedCultureCategory = 'All';
let broadcastData = null;
let offlineMeta = null;
let cachedPublishedActivities = [];
let cachedArticles = [];

let mapLocations = [];
let filteredMapLocations = [];
let activeMapFilter = 'Today';
let selectedMapIndex = 0;
let leafletMap = null;
let leafletMarkers = [];
let leafletRouteLine = null;
let mapInitialized = false;

document.addEventListener('DOMContentLoaded', () => {
  drawMekongCanvas('mekongCanvas');
  drawMekongCanvas('homeMekongCanvas');
  setupEventListeners();
  loadAllData();
  animateLoginEntrance();
});

// ================= ANIME.JS ANIMATION HELPERS =================

function runAnime(opts) {
  if (typeof window.anime === 'function') {
    window.anime(opts);
  }
}

function animateLoginEntrance() {
  runAnime({
    targets: '#view-login .login-sheet > *',
    translateY: [18, 0],
    opacity: [0, 1],
    delay: typeof window.anime === 'function' ? window.anime.stagger(55) : 0,
    duration: 480,
    easing: 'easeOutCubic'
  });
}

function animateHomeTiles() {
  runAnime({
    targets: '#tab-home .home-tile-lg',
    translateY: [16, 0],
    scale: [0.96, 1],
    opacity: [0, 1],
    delay: typeof window.anime === 'function' ? window.anime.stagger(55, { start: 60 }) : 0,
    duration: 420,
    easing: 'easeOutCubic'
  });
  runAnime({
    targets: '#tab-home .home-bottom-strip',
    translateY: [12, 0],
    opacity: [0, 1],
    duration: 420,
    delay: 220,
    easing: 'easeOutCubic'
  });
}

function animateStagger(selector) {
  runAnime({
    targets: selector,
    translateY: [14, 0],
    opacity: [0, 1],
    delay: typeof window.anime === 'function' ? window.anime.stagger(45) : 0,
    duration: 360,
    easing: 'easeOutCubic'
  });
}

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function setupEventListeners() {
  document.getElementById('loginContinueBtn').addEventListener('click', handleLogin);
  document.getElementById('inviteCodeInput').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') handleLogin();
  });

  document.getElementById('staffLoginLink').addEventListener('click', (e) => {
    e.preventDefault();
    const label = document.getElementById('loginFieldLabel');
    const input = document.getElementById('inviteCodeInput');
    if (label) label.textContent = 'University email or staff code';
    if (input) {
      input.value = '';
      input.placeholder = 'Enter university email or coordinator code';
      input.focus();
    }
  });

  document.getElementById('guideInput').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') handleSendGuide();
  });

  const toggleStepsEl = document.getElementById('toggleSteps');
  if (toggleStepsEl) {
    toggleStepsEl.addEventListener('change', (e) => {
      showSteps = e.target.checked;
    });
  }

  const toggleOfflineEl = document.getElementById('toggleOffline');
  if (toggleOfflineEl) {
    toggleOfflineEl.addEventListener('change', (e) => {
      if (e.target.checked) {
        syncOfflineMeta();
      }
    });
  }
}

async function loadAllData() {
  await loadBroadcastNotice();
  await Promise.all([
    syncOfflineMeta(),
    loadHomeDashboard(),
    loadPlanDays(activePlanDay),
    loadCultureModule(selectedCultureCategory),
    loadMapLocations(),
    loadMoreTabCounts()
  ]);
  seedInitialChat();
}

function setTextSize(isLarge) {
  document.body.classList.toggle('text-large', isLarge);
  const normalBtn = document.getElementById('tsNormalBtn');
  const largeBtn = document.getElementById('tsLargeBtn');
  if (normalBtn) normalBtn.classList.toggle('active', !isLarge);
  if (largeBtn) largeBtn.classList.toggle('active', isLarge);
}

// ================= BILINGUAL COMING SOON HELPER =================

function getComingSoonHtml(enMsg = 'Nothing to display yet.', viMsg = 'Chưa có nội dung để hiển thị.') {
  return `
    <div class="coming-soon-card">
      <div class="cs-icon">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"></circle>
          <polyline points="12 6 12 12 16 14"></polyline>
        </svg>
      </div>
      <div class="cs-title-en">Coming soon</div>
      <div class="cs-title-vi">Sắp ra mắt</div>
      <div class="cs-desc-en">${escapeHtml(enMsg)}</div>
      <div class="cs-desc-vi">${escapeHtml(viMsg)}</div>
    </div>
  `;
}

// ================= AUTHENTICATION =================

async function handleLogin() {
  const input = document.getElementById('inviteCodeInput');
  const errorEl = document.getElementById('loginError');
  const code = input ? input.value.trim() : '';

  if (!code) {
    if (errorEl) {
      errorEl.textContent = 'Please enter your invite code or university email.';
      errorEl.style.display = 'block';
    }
    return;
  }

  if (errorEl) errorEl.style.display = 'none';

  try {
    const res = await fetch(`${API_BASE}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ invite_code: code })
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      if (errorEl) {
        errorEl.textContent = errData.detail || 'Invalid invite code or email. Check with your coordinator.';
        errorEl.style.display = 'block';
      }
      return;
    }

    currentUser = await res.json();
    updateUserLabels();

    document.getElementById('view-login').classList.remove('active');
    document.getElementById('view-main').classList.add('active');
    await loadAllData();
    switchNav(0);
  } catch (err) {
    if (errorEl) {
      errorEl.textContent = 'Unable to connect to the server. Make sure the backend is running.';
      errorEl.style.display = 'block';
    }
  }
}

function updateUserLabels() {
  if (!currentUser) return;
  const firstName = (currentUser.full_name || '').split(' ')[0] || 'Guest';
  const initials = currentUser.avatar_initials || firstName.substring(0, 2).toUpperCase();
  const cohortLabel = `Day ${activePlanDay} · ${currentUser.cohort || ''}`;

  document.getElementById('homeUserName').textContent = firstName;
  document.getElementById('homeUserCohort').textContent = cohortLabel;
  document.getElementById('homeUserAvatar').textContent = initials;
  document.getElementById('moreUserName').textContent = currentUser.full_name || '';
  document.getElementById('moreUserAvatar').textContent = initials;
  document.getElementById('moreUserRole').textContent = (currentUser.role || '').toUpperCase();
  document.getElementById('moreUserCohort').textContent = currentUser.cohort || '';
  document.getElementById('planCohortSubtitle').textContent = cohortLabel;
}

function handleSignOut() {
  currentUser = null;
  const errorEl = document.getElementById('loginError');
  if (errorEl) errorEl.style.display = 'none';
  document.getElementById('view-main').classList.remove('active');
  document.getElementById('view-login').classList.add('active');
}

// ================= PRIMARY NAVIGATION =================

function switchNav(tabIndex) {
  currentTab = tabIndex;

  // Bottom nav items order: Home(0), Plan(1), Map(2 in navBtns = tab 3), Culture(3 in navBtns = tab 4), More(4 in navBtns = tab 5)
  const navBtns = document.querySelectorAll('.mobile-nav-bar .nav-item');
  navBtns.forEach((btn, idx) => {
    let isActive = false;
    if (tabIndex === 0 && idx === 0) isActive = true;
    if (tabIndex === 1 && idx === 1) isActive = true;
    if (tabIndex === 3 && idx === 2) isActive = true;
    if (tabIndex === 4 && idx === 3) isActive = true;
    if (tabIndex === 5 && idx === 4) isActive = true;
    btn.classList.toggle('active', isActive);
  });

  const tabContents = document.querySelectorAll('.tab-content');
  tabContents.forEach(tc => tc.classList.remove('active'));

  const tabIds = ['tab-home', 'tab-plan', 'tab-ask', 'tab-map', 'tab-culture', 'tab-more'];
  const target = document.getElementById(tabIds[tabIndex]);
  if (target) {
    target.classList.add('active');
    runAnime({
      targets: target,
      opacity: [0.4, 1],
      translateY: [10, 0],
      duration: 280,
      easing: 'easeOutCubic'
    });
  }

  if (tabIndex === 0) {
    drawMekongCanvas('homeMekongCanvas');
    loadHomeDashboard();
    animateHomeTiles();
  }
  if (tabIndex === 1) loadPlanDays(activePlanDay);
  if (tabIndex === 3) {
    initLeafletMap();
    loadMapLocations();
    setTimeout(() => {
      if (leafletMap) {
        leafletMap.invalidateSize();
        renderMapPins(true);
      }
    }, 150);
  }
  if (tabIndex === 4) loadCultureModule(selectedCultureCategory);
  if (tabIndex === 5) loadMoreTabCounts();
}

// Work in progress notice for QR Scanner
function showScanWipNotice() {
  const existing = document.getElementById('scanWipOverlay');
  if (existing) existing.remove();

  const overlay = document.createElement('div');
  overlay.id = 'scanWipOverlay';
  overlay.style.cssText = `
    position: fixed; inset: 0; background: rgba(0,0,0,0.5);
    z-index: 999; display: flex; align-items: flex-end; justify-content: center;
  `;
  overlay.innerHTML = `
    <div style="
      background: var(--color-card); border-radius: 24px 24px 0 0;
      padding: 28px 24px 36px; max-width: 480px; width: 100%;
      box-shadow: 0 -4px 24px rgba(0,0,0,0.12);
    ">
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="
          width: 48px; height: 48px; background: var(--color-straw);
          border-radius: 50%; display: flex; align-items: center; justify-content: center;
        ">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--color-ink)" stroke-width="2">
            <path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/>
            <path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/>
          </svg>
        </div>
        <div>
          <div style="font-family: 'Fraunces', serif; font-size: 20px; font-weight: 700; color: var(--color-ink);">QR Scanner</div>
          <div style="font-size: 13px; font-weight: 700; color: var(--color-clay);">Work in progress · Sắp ra mắt</div>
        </div>
      </div>
      <p style="font-size: 14px; color: var(--color-ink); line-height: 1.5; margin-bottom: 8px;">
        QR code scanning and landmark recognition will be available in an upcoming release.
      </p>
      <p style="font-size: 13px; font-style: italic; color: var(--color-muted); line-height: 1.4; margin-bottom: 20px;">
        Tính năng quét mã QR đang được hoàn thiện và sẽ sớm ra mắt.
      </p>
      <button onclick="document.getElementById('scanWipOverlay').remove()" style="
        width: 100%; padding: 14px; background: var(--color-river-green); color: white;
        border: none; border-radius: 16px; font-size: 15px; font-weight: 700;
        cursor: pointer; font-family: 'Nunito Sans', sans-serif;
      ">Close / Đóng</button>
    </div>
  `;
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });
  document.body.appendChild(overlay);
  runAnime({
    targets: overlay.firstElementChild,
    translateY: [80, 0],
    opacity: [0, 1],
    duration: 320,
    easing: 'easeOutCubic'
  });
}

// ================= BROADCAST & OFFLINE META =================

async function syncOfflineMeta() {
  try {
    const res = await fetch(`${API_BASE}/api/itinerary/sync-offline`);
    if (!res.ok) return;
    offlineMeta = await res.json();
    cachedPublishedActivities = offlineMeta.activities || [];

    const updatedText = offlineMeta.last_updated
      ? `Last saved ${offlineMeta.last_updated}`
      : 'Coming soon · Sắp ra mắt';

    const offlineBannerText = document.getElementById('offlineBannerText');
    if (offlineBannerText) {
      offlineBannerText.textContent = offlineMeta.total_activities > 0
        ? `You're offline. Searching saved schedule (${offlineMeta.last_updated || 'synced'}).`
        : "You're offline. No saved schedule yet (Sắp ra mắt).";
    }

    const planFooter = document.getElementById('planSyncFooter');
    if (planFooter) {
      if (offlineMeta.total_activities > 0) {
        planFooter.textContent = `Updated by coordinator (${offlineMeta.last_updated || `v${offlineMeta.version}`}). Works offline.`;
        planFooter.style.display = 'block';
      } else {
        planFooter.style.display = 'none';
      }
    }

    const itLabel = document.getElementById('itineraryStatusLabel');
    if (itLabel) {
      itLabel.textContent = offlineMeta.total_activities > 0
        ? `${offlineMeta.total_activities} activities · v${offlineMeta.version}${offlineMeta.last_updated ? ` (${offlineMeta.last_updated})` : ''}`
        : 'Coming soon · Sắp ra mắt';
    }

    const offlineSub = document.getElementById('offlineSettingSub');
    if (offlineSub) {
      offlineSub.textContent = updatedText;
    }
  } catch (_) {}
}

async function loadBroadcastNotice() {
  const homeBanner = document.getElementById('homeBroadcastBanner');
  const homeBannerText = document.getElementById('homeBroadcastText');
  const homeComingSoon = document.getElementById('homeComingSoon');
  const planAlert = document.getElementById('planCoordinatorAlert');
  const planAlertEl = document.getElementById('planAlertText');

  try {
    const res = await fetch(`${API_BASE}/api/broadcast`);
    if (!res.ok) throw new Error('Broadcast fetch failed');
    const data = await res.json();
    broadcastData = data;

    if (data.day_number) {
      programDay = data.day_number;
      activePlanDay = data.day_number;
      updateUserLabels();
    }

    const msg = (data.message || '').trim();
    if (msg) {
      const timePart = (data.time_label || '').trim();
      const prefix = timePart ? `Coordinator update, ${escapeHtml(timePart)}.` : 'Coordinator update:';
      const msgHtml = `<strong>${prefix}</strong> ${escapeHtml(msg)}`;

      if (planAlertEl && planAlert) {
        planAlertEl.innerHTML = msgHtml;
        planAlert.style.display = 'flex';
      }
      if (homeBanner && homeBannerText && homeComingSoon) {
        homeBannerText.innerHTML = msgHtml;
        homeBanner.style.display = 'flex';
        homeComingSoon.style.display = 'none';
      }
    } else {
      if (planAlert) planAlert.style.display = 'none';
      if (homeBanner) homeBanner.style.display = 'none';
      if (homeComingSoon) homeComingSoon.style.display = 'block';
    }
  } catch (err) {
    console.error('Failed to load broadcast notice:', err);
    if (planAlert) planAlert.style.display = 'none';
    if (homeBanner) homeBanner.style.display = 'none';
    if (homeComingSoon) homeComingSoon.style.display = 'block';
  }
}

// ================= DASHBOARD (MAIN) =================

async function loadHomeDashboard() {
  // Home dashboard stays strictly non-scrollable (greeting + search + 2x2 tiles + bottom strip)
  await loadBroadcastNotice();
}

// ================= PLANNER TAB =================

async function loadPlanDays(day = activePlanDay) {
  activePlanDay = day;

  const pillsContainer = document.getElementById('planDayPills');
  if (pillsContainer) {
    pillsContainer.innerHTML = '';
    for (let i = 1; i <= 7; i++) {
      const pill = document.createElement('div');
      pill.className = `day-pill ${i === day ? 'active' : ''}`;
      pill.onclick = () => loadPlanDays(i);
      pill.innerHTML = `<span class="dp-sub">Day</span><span class="dp-num">${i}</span>`;
      pillsContainer.appendChild(pill);
    }
  }

  document.getElementById('planDayHeading').textContent = `Day ${day}`;

  try {
    const res = await fetch(`${API_BASE}/api/itinerary?day=${day}`);
    const activities = res.ok ? await res.json() : [];
    renderPlanList(activities);
  } catch (err) {
    console.error('Failed to load plan activities:', err);
    renderPlanList([]);
  }
}

function renderPlanList(activities) {
  const container = document.getElementById('planActivitiesList');
  container.innerHTML = '';
  const count = activities ? activities.length : 0;
  document.getElementById('planCountHeading').textContent = `${count} ${count === 1 ? 'activity' : 'activities'}`;

  if (!activities || activities.length === 0) {
    container.innerHTML = getComingSoonHtml(
      `No activities scheduled yet for Day ${activePlanDay}.`,
      `Chưa có hoạt động nào được lên lịch cho Ngày ${activePlanDay}.`
    );
    return;
  }

  activities.forEach((act, idx) => {
    const isHighlight = idx === 0;
    const item = document.createElement('div');
    item.className = 'plan-item';
    item.innerHTML = `
      <div class="plan-time-badge ${isHighlight ? 'clay' : ''}">${escapeHtml(act.start_time)}</div>
      <div class="flex-1">
        <div class="card-title">${escapeHtml(act.title)}</div>
        <div class="card-sub">${escapeHtml(act.venue_name)} · ${escapeHtml(act.target_audience)}</div>
      </div>
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7A7067" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline></svg>
    `;
    item.onclick = () => {
      switchNav(2);
      submitGuideQuery(`What time is ${act.title}?`);
    };
    container.appendChild(item);
  });
  animateStagger('#planActivitiesList .plan-item');
}

// ================= CULTURE TAB =================

function selectCultureCategory(cat) {
  const newCat = (selectedCultureCategory === cat) ? 'All' : cat;
  selectedCultureCategory = newCat;
  document.querySelectorAll('#cultureCategoriesRow .cat-circle-wrap').forEach(wrap => {
    const label = wrap.querySelector('span')?.textContent?.trim();
    const circle = wrap.querySelector('.cat-circle');
    if (circle) {
      circle.style.outline = (label === newCat) ? '3px solid var(--color-ink)' : 'none';
      circle.style.outlineOffset = '2px';
    }
  });
  loadCultureModule(newCat);
}

async function loadCultureModule(category = 'All') {
  selectedCultureCategory = category;
  document.getElementById('placesSectionTitle').textContent = (category === 'All') ? 'Articles & Places' : `${category}`;

  try {
    const url = (category === 'All')
      ? `${API_BASE}/api/culture/articles`
      : `${API_BASE}/api/culture/articles?category=${encodeURIComponent(category)}`;
    const res = await fetch(url);
    const articles = res.ok ? await res.json() : [];
    if (category === 'All') cachedArticles = articles;
    renderPlacesGrid(articles);

    const wordArt = articles.find(a => a.vietnamese_word && a.vietnamese_word.trim() !== '');
    const wordCard = document.getElementById('wordToLearnCard');
    if (wordArt) {
      wordCard.style.display = 'flex';
      document.getElementById('wordVietText').textContent = wordArt.vietnamese_word;
      document.getElementById('wordTransText').textContent = wordArt.word_translation || '';
    } else {
      wordCard.style.display = 'none';
    }
  } catch (err) {
    console.error('Failed to load culture module:', err);
    renderPlacesGrid([]);
    document.getElementById('wordToLearnCard').style.display = 'none';
  }
}

function renderPlacesGrid(articles) {
  const grid = document.getElementById('placesGrid');
  grid.innerHTML = '';
  const count = articles ? articles.length : 0;
  document.getElementById('cultureCount').textContent = `${count} ${count === 1 ? 'article' : 'articles'}`;

  if (!articles || articles.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1 / -1;">
        ${getComingSoonHtml(
          selectedCultureCategory === 'All'
            ? 'No cultural articles have been published yet.'
            : `No articles available in "${selectedCultureCategory}".`,
          'Chưa có bài viết văn hóa nào được công bố.'
        )}
      </div>
    `;
    return;
  }

  articles.forEach(art => {
    const card = document.createElement('div');
    card.className = 'place-card';
    card.innerHTML = `
      <div class="place-art">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#2D4A36" stroke-width="2">
          ${art.category === 'Markets'
            ? '<path d="M2 19h20"></path><path d="M3 15l4-8 5 8"></path>'
            : '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>'}
        </svg>
      </div>
      <div class="place-body">
        <div class="place-title">${escapeHtml(art.title)}</div>
        <div class="place-tag">${escapeHtml(art.category)}</div>
      </div>
    `;
    card.onclick = () => openCultureDetail(art.content_id);
    grid.appendChild(card);
  });
  animateStagger('#placesGrid .place-card');
}

function copyLearnedWord() {
  const word = document.getElementById('wordVietText').textContent;
  navigator.clipboard.writeText(word);
}

async function openCultureDetail(contentId) {
  try {
    const res = await fetch(`${API_BASE}/api/culture/articles/${encodeURIComponent(contentId)}`);
    if (!res.ok) return;
    const art = await res.json();
    renderCultureDetail(art);
    document.getElementById('modal-culture-detail').classList.add('open');
    drawMekongCanvas('detailCanvas');
  } catch (err) {
    console.error('Failed to load article detail:', err);
  }
}

function closeCultureDetail() {
  document.getElementById('modal-culture-detail').classList.remove('open');
}

function renderCultureDetail(art) {
  const matchedPlanAct = cachedPublishedActivities.find(
    a => (art.location_id && a.location_id === art.location_id) ||
         (a.title && art.title && a.title.toLowerCase().includes(art.title.toLowerCase()))
  );

  const container = document.getElementById('detailSheetContent');
  container.innerHTML = `
    <h2 class="landmark-heading" style="font-size: 26px;">${escapeHtml(art.title)}</h2>
    <div style="font-size: 13.5px; color: var(--color-muted); margin: 4px 0 12px 0;">
      ${escapeHtml(art.category)} · ${escapeHtml(art.source_author)} (${escapeHtml(art.source_date)})
    </div>
    ${matchedPlanAct ? `
      <div style="display: inline-flex; align-items: center; gap: 6px; background-color: var(--color-river-green); color: white; padding: 6px 12px; border-radius: 16px; font-size: 12px; font-weight: 700;">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect></svg>
        <span>On your plan · Day ${matchedPlanAct.day_number}, ${escapeHtml(matchedPlanAct.start_time)}</span>
      </div>
    ` : ''}

    <div style="margin: 18px 0 12px 0; font-size: 14.5px; line-height: 1.5; color: var(--color-ink);">${escapeHtml(art.summary)}</div>
    <div style="font-size: 13.5px; color: var(--color-muted); line-height: 1.5; margin-bottom: 16px;">${escapeHtml(art.content)}</div>

    ${art.fact_1 ? `
    <div style="background-color: var(--color-straw); border-radius: 16px; padding: 14px; margin-bottom: 10px;">
      <div style="font-size: 12px; font-weight: 700; color: var(--color-muted);">Fact 1</div>
      <div style="font-size: 13.5px; color: var(--color-ink); margin-top: 4px;">${escapeHtml(art.fact_1)}</div>
    </div>` : ''}

    ${art.fact_2 ? `
    <div style="background-color: #D4E7F2; border-radius: 16px; padding: 14px; margin-bottom: 16px;">
      <div style="font-size: 12px; font-weight: 700; color: var(--color-muted);">Fact 2</div>
      <div style="font-size: 13.5px; color: var(--color-ink); margin-top: 4px;">${escapeHtml(art.fact_2)}</div>
    </div>` : ''}

    ${art.vietnamese_word ? `
    <div class="word-card" style="margin-bottom: 16px;">
      <div>
        <div class="word-viet">${escapeHtml(art.vietnamese_word)}</div>
        <div class="word-trans">${escapeHtml(art.word_translation || '')}</div>
      </div>
      <button class="icon-circle-btn bg-white" onclick="navigator.clipboard.writeText('${escapeHtml(art.vietnamese_word)}')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2A2119" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect></svg>
      </button>
    </div>` : ''}

    <div class="ticket-stub mb-3">
      <span class="stub-code">${escapeHtml(art.source_date || 'SRC')}</span>
      <span class="stub-name">${escapeHtml(art.source_label)} — ${escapeHtml(art.source_title)}</span>
    </div>

    <div style="display: flex; gap: 10px; margin-top: 20px;">
      <button class="btn btn-clay flex-1" onclick="closeCultureDetail(); switchNav(2); submitGuideQuery('Tell me about ' + ${JSON.stringify(art.title)});">Ask the guide about this</button>
      <button class="icon-circle-btn" style="background-color: var(--color-card); border: 1.5px solid var(--color-divider); width: 50px; height: 50px;" onclick="closeCultureDetail(); switchNav(3);" title="View on Map">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2A2119" stroke-width="2"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"></polygon></svg>
      </button>
    </div>
  `;
}

// ================= MAP TAB (DYNAMIC FROM POSTGRESQL) =================

let todayLocationIds = new Set();
let cultureLocationIds = new Set();

async function loadMapLocations() {
  try {
    const [locRes, itRes, artRes] = await Promise.all([
      fetch(`${API_BASE}/api/locations`),
      fetch(`${API_BASE}/api/itinerary?day=${programDay}`),
      fetch(`${API_BASE}/api/culture/articles`)
    ]);

    mapLocations = locRes.ok ? await locRes.json() : [];
    const todayActs = itRes.ok ? await itRes.json() : [];
    const arts = artRes.ok ? await artRes.json() : [];

    todayLocationIds = new Set(todayActs.map(a => a.location_id).filter(Boolean));
    cultureLocationIds = new Set(arts.map(a => a.location_id).filter(Boolean));

    applyMapFilter();
  } catch (err) {
    console.error('Failed to load locations:', err);
    mapLocations = [];
    applyMapFilter();
  }
}

function filterMapPoints(filterType) {
  activeMapFilter = filterType;
  document.querySelectorAll('.map-top-chips .chip').forEach(c => {
    const txt = c.textContent.trim();
    c.classList.toggle('active', txt.startsWith(filterType));
  });
  selectedMapIndex = 0;
  applyMapFilter();
}

function applyMapFilter() {
  if (activeMapFilter === 'Today') {
    filteredMapLocations = mapLocations.filter(loc => todayLocationIds.has(loc.location_id));
  } else if (activeMapFilter === 'Culture') {
    filteredMapLocations = mapLocations.filter(loc => cultureLocationIds.has(loc.location_id));
  } else {
    filteredMapLocations = [...mapLocations];
  }

  if (selectedMapIndex >= filteredMapLocations.length) {
    selectedMapIndex = 0;
  }

  renderMapBottomCard();
  setTimeout(renderMapPins, 30);
}

function renderMapBottomCard() {
  const bottomCard = document.getElementById('mapBottomCard');
  const comingSoonCard = document.getElementById('mapComingSoonCard');

  if (!filteredMapLocations || filteredMapLocations.length === 0) {
    bottomCard.style.display = 'none';
    comingSoonCard.style.display = 'block';
    const msgEn = mapLocations.length === 0
      ? 'No map landmarks have been added yet.'
      : `No locations mapped for "${activeMapFilter}".`;
    const msgVi = mapLocations.length === 0
      ? 'Chưa có địa điểm nào trên bản đồ.'
      : 'Chưa có địa điểm nào cho bộ lọc này.';
    comingSoonCard.innerHTML = getComingSoonHtml(msgEn, msgVi);
    return;
  }

  comingSoonCard.style.display = 'none';
  bottomCard.style.display = 'block';

  const loc = filteredMapLocations[selectedMapIndex];
  const chipsContainer = document.getElementById('mapPinChips');
  if (chipsContainer) {
    chipsContainer.innerHTML = filteredMapLocations.map((item, idx) => `
      <button class="map-pin-chip ${idx === selectedMapIndex ? 'active' : ''}" onclick="selectMapLocation(${idx})">
        ${idx + 1}. ${escapeHtml(item.map_reference || item.name)}
      </button>
    `).join('');
  }

  document.getElementById('mapPinNumber').textContent = String(selectedMapIndex + 1);
  document.getElementById('mapPinName').textContent = loc.name;
  document.getElementById('mapPinSub').textContent = loc.address || loc.map_reference || 'Can Tho';

  document.getElementById('mapDirectionsBtn').onclick = () => showLocationDetailsModal(loc);
  document.getElementById('mapAskBtn').onclick = () => askAboutPlace(`Tell me about ${loc.name}`);
}

function selectMapLocation(index) {
  if (index < 0 || index >= filteredMapLocations.length) return;
  selectedMapIndex = index;
  renderMapBottomCard();
  renderMapPins(false);
  const loc = filteredMapLocations[index];
  if (leafletMap && typeof loc.latitude === 'number' && typeof loc.longitude === 'number') {
    leafletMap.panTo([loc.latitude, loc.longitude], { animate: true });
  }
}

function showLocationDetailsModal(loc) {
  const existing = document.getElementById('locDetailOverlay');
  if (existing) existing.remove();

  const overlay = document.createElement('div');
  overlay.id = 'locDetailOverlay';
  overlay.style.cssText = `
    position: fixed; inset: 0; background: rgba(0,0,0,0.45);
    z-index: 999; display: flex; align-items: flex-end; justify-content: center;
  `;
  overlay.innerHTML = `
    <div style="
      background: var(--color-card); border-radius: 24px 24px 0 0;
      padding: 24px 22px 32px; max-width: 480px; width: 100%;
    ">
      <h3 style="font-family:'Fraunces',serif; font-size:21px; font-weight:700; color:var(--color-ink); margin-bottom:4px;">
        ${escapeHtml(loc.name)}
      </h3>
      <div style="font-size:13px; color:var(--color-muted); margin-bottom:12px;">
        ${escapeHtml(loc.address || 'Can Tho, Vietnam')}
      </div>
      <p style="font-size:14px; line-height:1.5; color:var(--color-ink); margin-bottom:12px;">
        ${escapeHtml(loc.description || 'Registered program destination.')}
      </p>
      ${loc.latitude && loc.longitude ? `
        <div style="font-size:12px; color:var(--color-delta-blue); font-weight:700; margin-bottom:16px;">
          Coordinates: ${loc.latitude.toFixed(4)}, ${loc.longitude.toFixed(4)}
        </div>
      ` : ''}
      <button onclick="document.getElementById('locDetailOverlay').remove()" style="
        width:100%; padding:13px; background:var(--color-river-green); color:white;
        border:none; border-radius:16px; font-weight:700; font-size:14px; cursor:pointer;
      ">Close</button>
    </div>
  `;
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
  document.body.appendChild(overlay);
}

function askAboutPlace(query) {
  switchNav(2);
  submitGuideQuery(query);
}

// ================= MORE / PROFILE TAB =================

async function loadMoreTabCounts() {
  try {
    const res = await fetch(`${API_BASE}/api/culture/articles`);
    const articles = res.ok ? await res.json() : [];
    const count = articles ? articles.length : 0;

    const titleEl = document.getElementById('approvedArticlesCountTitle');
    if (titleEl) {
      titleEl.textContent = `${count} approved article${count !== 1 ? 's' : ''}`;
    }

    const descEl = document.getElementById('approvedArticlesSourcesDesc');
    if (descEl) {
      if (count > 0) {
        const sources = [...new Set(articles.map(a => a.source_label).filter(Boolean))];
        descEl.textContent = sources.slice(0, 2).join(', ') + (sources.length > 2 ? ` +${sources.length - 2} more` : '');
      } else {
        descEl.textContent = 'Coming soon · Sắp ra mắt';
      }
    }
  } catch (_) {}
}

// ================= ASK THE GUIDE (AI) =================

function seedInitialChat() {
  const thread = document.getElementById('chatThread');
  if (!thread) return;
  thread.innerHTML = `
    <div style="text-align: center; padding: 24px 12px; color: var(--color-muted);">
      <div style="font-family: 'Fraunces', serif; font-size: 20px; font-weight: 700; color: var(--color-ink); margin-bottom: 6px;">
        Automated Can Tho Guide
      </div>
      <div style="font-size: 13px; line-height: 1.5;">
        Ask about the exchange itinerary or verified Can Tho culture.<br>
        <em>Hỏi về lịch trình giao lưu hoặc văn hóa Cần Thơ đã kiểm duyệt.</em>
      </div>
    </div>
  `;
}

async function submitGuideQuery(query) {
  if (!query) return;
  const thread = document.getElementById('chatThread');

  const userDiv = document.createElement('div');
  userDiv.className = 'user-bubble';
  userDiv.textContent = query;
  thread.appendChild(userDiv);
  thread.scrollTop = thread.scrollHeight;

  try {
    const res = await fetch(`${API_BASE}/api/guide/ask`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ question: query, offline_mode: isOffline })
    });
    const data = await res.json();
    renderGuideResponse(data);
  } catch (err) {
    renderGuideResponse({
      question: query,
      answer: "Unable to reach the guide server right now. Check your connection.\n\nKhông thể kết nối đến máy chủ hướng dẫn.",
      source_type: 'schedule',
      source_stub: null,
      status: 'offline',
      steps: ['Server unreachable: please check your network connection.'],
      try_next: []
    });
  }
}

function renderGuideResponse(data) {
  const thread = document.getElementById('chatThread');
  const card = document.createElement('div');
  card.className = 'guide-card';

  const isUnsupported = data.status === 'not_in_sources';
  const isOfflineStatus = data.status === 'offline';

  let headerHtml = '';
  if (isUnsupported) {
    headerHtml = `<span class="status-chip chip-straw" style="align-self: flex-start;">Not in my sources</span>`;
  } else if (isOfflineStatus) {
    headerHtml = `<div class="guide-meta-stub"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path></svg><span>From the saved schedule</span></div>`;
  } else {
    headerHtml = `<div class="guide-meta-stub"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect></svg><span>${data.source_type === 'culture' ? 'From Can Tho articles' : 'From the itinerary'}</span></div>`;
  }

  let stepsHtml = '';
  if (data.steps && data.steps.length > 0) {
    stepsHtml = data.steps.map((s, idx) => `
      <div class="step-row"><span class="step-num">${idx + 1}</span><span>${escapeHtml(s)}</span></div>
    `).join('');
  }

  let tryNextHtml = '';
  if (data.try_next && data.try_next.length > 0) {
    tryNextHtml = `
      <div style="font-size: 12px; color: var(--color-muted); font-weight: 600; margin-top: 6px;">${isUnsupported ? 'Try asking' : 'Try next'}</div>
      <div class="quick-chips-row" style="padding: 4px 0 0 0;">
        ${data.try_next.map(t => `<button class="chip" onclick='submitGuideQuery(${JSON.stringify(t)})'>${escapeHtml(t)}</button>`).join('')}
      </div>
    `;
  }

  card.innerHTML = `
    ${headerHtml}
    <div class="guide-answer" style="white-space: pre-line;">${escapeHtml(data.answer)}</div>
    ${data.source_stub && !isUnsupported ? `<div class="ticket-stub"><span class="stub-code">1</span><span class="stub-name">${escapeHtml(data.source_stub)}</span></div>` : ''}
    ${data.note ? `<div style="font-size: 12px; color: var(--color-muted); font-style: italic;">${escapeHtml(data.note)}</div>` : ''}
    ${isUnsupported ? `<div style="font-size: 12.5px; color: var(--color-river-green); font-weight: 700;">Contact your exchange coordinator for external info.</div>` : ''}
    ${showSteps && stepsHtml ? `
      <details style="margin-top: 4px;">
        <summary style="font-size: 13px; font-weight: 700; color: var(--color-delta-blue); cursor: pointer;">How I answered ⌵</summary>
        <div class="guide-steps-box mt-2">${stepsHtml}</div>
      </details>
    ` : ''}
    ${tryNextHtml}
  `;

  thread.appendChild(card);
  thread.scrollTop = thread.scrollHeight;
  runAnime({
    targets: card,
    translateY: [14, 0],
    opacity: [0, 1],
    duration: 300,
    easing: 'easeOutCubic'
  });
}

function handleSendGuide() {
  const input = document.getElementById('guideInput');
  const val = input.value.trim();
  if (val) {
    input.value = '';
    submitGuideQuery(val);
  }
}

function toggleGuideOffline() {
  isOffline = !isOffline;
  const pill = document.getElementById('aiStatusPill');
  const text = document.getElementById('aiStatusText');
  const banner = document.getElementById('offlineAlertBanner');

  if (isOffline) {
    pill.classList.add('offline');
    text.textContent = 'Offline';
    banner.style.display = 'flex';
    document.getElementById('guideInput').placeholder = 'Type a date or a place name';
  } else {
    pill.classList.remove('offline');
    text.textContent = 'Online';
    banner.style.display = 'none';
    document.getElementById('guideInput').placeholder = 'Ask about the schedule or Can Tho';
  }
}

// ================= CANVAS ARTWORK & DYNAMIC MAP =================

function drawMekongCanvas(canvasId) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const w = canvas.width;
  const h = canvas.height;

  // Soft warm peach-to-cream sky gradient matching reference
  const skyGrad = ctx.createLinearGradient(0, 0, 0, h * 0.72);
  skyGrad.addColorStop(0, '#FBE2C4');
  skyGrad.addColorStop(1, '#FFF3E4');
  ctx.fillStyle = skyGrad;
  ctx.fillRect(0, 0, w, h);

  // Soft sun
  ctx.fillStyle = 'rgba(240, 175, 86, 0.38)';
  ctx.beginPath();
  ctx.arc(w * 0.76, h * 0.30, h * 0.23, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#F2B95E';
  ctx.beginPath();
  ctx.arc(w * 0.76, h * 0.30, h * 0.14, 0, Math.PI * 2);
  ctx.fill();

  // Distant sage hills
  ctx.fillStyle = '#B7C794';
  ctx.beginPath();
  ctx.moveTo(0, h * 0.60);
  ctx.quadraticCurveTo(w * 0.22, h * 0.44, w * 0.48, h * 0.56);
  ctx.quadraticCurveTo(w * 0.76, h * 0.42, w, h * 0.58);
  ctx.lineTo(w, h);
  ctx.lineTo(0, h);
  ctx.closePath();
  ctx.fill();

  // Mid olive bank
  ctx.fillStyle = '#8AA45B';
  ctx.beginPath();
  ctx.moveTo(0, h * 0.65);
  ctx.quadraticCurveTo(w * 0.35, h * 0.57, w * 0.65, h * 0.64);
  ctx.quadraticCurveTo(w * 0.86, h * 0.68, w, h * 0.62);
  ctx.lineTo(w, h);
  ctx.lineTo(0, h);
  ctx.closePath();
  ctx.fill();

  // Mekong / Hau River water
  const riverGrad = ctx.createLinearGradient(0, h * 0.68, 0, h);
  riverGrad.addColorStop(0, '#729CB1');
  riverGrad.addColorStop(1, '#558198');
  ctx.fillStyle = riverGrad;
  ctx.fillRect(0, h * 0.68, w, h * 0.32);

  // Subtle water ripples
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.35)';
  ctx.lineWidth = 1.8;
  ctx.beginPath();
  ctx.moveTo(w * 0.08, h * 0.78);
  ctx.quadraticCurveTo(w * 0.25, h * 0.76, w * 0.42, h * 0.78);
  ctx.moveTo(w * 0.56, h * 0.85);
  ctx.quadraticCurveTo(w * 0.75, h * 0.83, w * 0.92, h * 0.85);
  ctx.stroke();

  // Foliage clusters (olive/moss tones)
  ctx.fillStyle = '#5F7A3D';
  ctx.beginPath();
  ctx.arc(w * 0.10, h * 0.56, 22, 0, Math.PI * 2);
  ctx.arc(w * 0.18, h * 0.60, 16, 0, Math.PI * 2);
  ctx.arc(w * 0.90, h * 0.56, 20, 0, Math.PI * 2);
  ctx.fill();

  // Boat 1 (Warm terracotta canopy boat)
  ctx.fillStyle = '#7A4C2C';
  ctx.beginPath();
  ctx.moveTo(w * 0.58, h * 0.80);
  ctx.lineTo(w * 0.90, h * 0.80);
  ctx.lineTo(w * 0.84, h * 0.90);
  ctx.lineTo(w * 0.64, h * 0.90);
  ctx.closePath();
  ctx.fill();

  ctx.fillStyle = '#C2643F';
  ctx.beginPath();
  ctx.roundRect(w * 0.64, h * 0.66, w * 0.20, h * 0.14, [10, 10, 0, 0]);
  ctx.fill();

  // Cây bẹo pole on boat
  ctx.strokeStyle = '#5A3821';
  ctx.lineWidth = 2.5;
  ctx.beginPath();
  ctx.moveTo(w * 0.61, h * 0.80); ctx.lineTo(w * 0.61, h * 0.44);
  ctx.moveTo(w * 0.56, h * 0.47); ctx.lineTo(w * 0.66, h * 0.47);
  ctx.stroke();
  ctx.fillStyle = '#E4A93B';
  ctx.beginPath(); ctx.arc(w * 0.56, h * 0.53, 4.5, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#C2643F';
  ctx.beginPath(); ctx.arc(w * 0.66, h * 0.54, 4.5, 0, Math.PI * 2); ctx.fill();
}

function initLeafletMap() {
  if (mapInitialized || typeof window.L === 'undefined') return;
  const mapEl = document.getElementById('leafletMap');
  if (!mapEl) return;

  leafletMap = window.L.map('leafletMap', {
    zoomControl: false
  }).setView([10.0341, 105.7832], 14);

  window.L.control.zoom({ position: 'topright' }).addTo(leafletMap);

  window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(leafletMap);

  mapInitialized = true;
}

function renderMapPins(fitBounds = true) {
  if (!mapInitialized) initLeafletMap();
  if (!leafletMap || typeof window.L === 'undefined') return;

  leafletMarkers.forEach(m => leafletMap.removeLayer(m));
  leafletMarkers = [];
  if (leafletRouteLine) {
    leafletMap.removeLayer(leafletRouteLine);
    leafletRouteLine = null;
  }

  if (!filteredMapLocations || filteredMapLocations.length === 0) {
    return;
  }

  const coords = [];
  filteredMapLocations.forEach((loc, idx) => {
    const lat = typeof loc.latitude === 'number' ? loc.latitude : 10.0341;
    const lng = typeof loc.longitude === 'number' ? loc.longitude : 105.7832;
    const isSelected = idx === selectedMapIndex;

    const icon = window.L.divIcon({
      className: 'custom-leaflet-pin-wrap',
      html: `<div class="custom-leaflet-pin ${isSelected ? 'active' : ''}">${idx + 1}</div>`,
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });

    const marker = window.L.marker([lat, lng], { icon }).addTo(leafletMap);
    marker.bindTooltip(escapeHtml(loc.map_reference || loc.name), {
      direction: 'top',
      offset: [0, -14]
    });
    marker.on('click', () => selectMapLocation(idx));
    leafletMarkers.push(marker);
    coords.push([lat, lng]);
  });

  if (coords.length > 1) {
    leafletRouteLine = window.L.polyline(coords, {
      color: '#4F6B2C',
      weight: 2.5,
      opacity: 0.65,
      dashArray: '6, 6'
    }).addTo(leafletMap);
  }

  if (fitBounds && coords.length > 0) {
    if (coords.length === 1) {
      leafletMap.setView(coords[0], 15);
    } else {
      const bounds = window.L.latLngBounds(coords);
      leafletMap.fitBounds(bounds, { padding: [70, 70], maxZoom: 15 });
    }
  }
}

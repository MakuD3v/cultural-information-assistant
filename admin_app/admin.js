const API_BASE = 'http://localhost:8000';
let currentDay = 3;
let activeCultureCategory = 'All';
let adminActivitiesCache = [];
let adminCultureCache = [];
let adminLocationsCache = [];

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

document.addEventListener('DOMContentLoaded', async () => {
  renderDaySwitcher();
  initTabs();
  await Promise.all([
    loadDashboard(),
    loadBroadcastNotice(),
    loadLocationsOptions()
  ]);
  loadPlanner(currentDay);
  runAdminAnime({
    targets: '#statsGrid .stat-card',
    translateY: [14, 0],
    opacity: [0, 1],
    delay: typeof window.anime === 'function' ? window.anime.stagger(55) : 0,
    duration: 380,
    easing: 'easeOutCubic'
  });
});

function runAdminAnime(opts) {
  if (typeof window.anime === 'function') {
    window.anime(opts);
  }
}

function initTabs() {
  const tabs = document.querySelectorAll('.nav-tab');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const tabKey = tab.dataset.tab;
      document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
      const targetPane = document.getElementById(`tab-${tabKey}`);
      if (targetPane) {
        targetPane.classList.add('active');
        runAdminAnime({
          targets: targetPane,
          opacity: [0.3, 1],
          translateY: [8, 0],
          duration: 260,
          easing: 'easeOutCubic'
        });
      }

      const titleMap = {
        dashboard: 'Dashboard Overview',
        itinerary: 'Itinerary',
        culture: 'Culture Manager',
        locations: 'Map Locations',
        approvals: 'Broadcast & Approvals'
      };
      document.getElementById('pageMainTitle').textContent = titleMap[tabKey] || 'Dashboard Overview';

      if (tabKey === 'dashboard') { loadDashboard(); loadBroadcastNotice(); }
      if (tabKey === 'itinerary') loadPlanner(currentDay);
      if (tabKey === 'culture') loadCultureList(activeCultureCategory);
      if (tabKey === 'locations') loadLocationsList();
      if (tabKey === 'approvals') { loadApprovals(); loadBroadcastNotice(); }
    });
  });
}

function switchTab(tabName) {
  const tabBtn = document.querySelector(`.nav-tab[data-tab="${tabName}"]`);
  if (tabBtn) tabBtn.click();
}

function renderDaySwitcher() {
  const container = document.getElementById('daySwitcher');
  if (!container) return;
  container.innerHTML = '';
  for (let i = 1; i <= 7; i++) {
    const btn = document.createElement('button');
    btn.className = `day-btn ${i === currentDay ? 'active' : ''}`;
    btn.textContent = `Day ${i}`;
    btn.onclick = () => loadPlanner(i);
    container.appendChild(btn);
  }
}

async function loadLocationsOptions() {
  try {
    const res = await fetch(`${API_BASE}/api/locations`);
    if (!res.ok) return;
    adminLocationsCache = await res.json();

    const selectors = ['actLocationId', 'artLocationId'];
    selectors.forEach(selId => {
      const sel = document.getElementById(selId);
      if (!sel) return;
      const prevVal = sel.value;
      sel.innerHTML = '<option value="">-- None --</option>';
      adminLocationsCache.forEach(loc => {
        const opt = document.createElement('option');
        opt.value = loc.location_id;
        opt.textContent = `${loc.name} (${loc.location_id})`;
        sel.appendChild(opt);
      });
      if (prevVal) sel.value = prevVal;
    });
  } catch (_) {}
}

// ================= PLANNER TAB =================

async function loadPlanner(day = currentDay) {
  currentDay = day;
  document.getElementById('adminDayTitle').textContent = `Day ${day}`;
  document.querySelectorAll('.day-btn').forEach((btn, idx) => {
    btn.classList.toggle('active', (idx + 1) === day);
  });

  try {
    const res = await fetch(`${API_BASE}/api/admin/planner?day=${day}`);
    const data = await res.json();
    adminActivitiesCache = data.activities || [];
    renderActivities(adminActivitiesCache);
    document.getElementById('activityCountLabel').textContent =
      `${adminActivitiesCache.length} ${adminActivitiesCache.length === 1 ? 'activity' : 'activities'}`;

    const pendingCount = data.pending_reviews ? data.pending_reviews.length : 0;
    document.getElementById('navApprovalCount').textContent = String(pendingCount);
    if (pendingCount > 0) {
      document.getElementById('approvalAlert').style.display = 'flex';
      document.getElementById('alertMessageText').textContent =
        `${pendingCount} pending change request${pendingCount !== 1 ? 's' : ''} from faculty awaiting review.`;
    } else {
      document.getElementById('approvalAlert').style.display = 'none';
    }
  } catch (err) {
    console.error('Failed to load planner data:', err);
  }
}

function renderActivities(activities) {
  const listEl = document.getElementById('activityList');
  listEl.innerHTML = '';

  if (!activities || activities.length === 0) {
    listEl.innerHTML = `
      <div class="coming-soon-card">
        <div class="cs-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
        </div>
        <div class="cs-title-en">Coming soon</div>
        <div class="cs-title-vi">Sắp ra mắt</div>
        <div class="cs-desc-en">No activities are scheduled yet for Day ${currentDay}.</div>
        <div class="cs-desc-vi">Chưa có hoạt động nào được lên lịch cho Ngày ${currentDay}.</div>
        <button class="btn btn-primary-sm" onclick="openAddModal()">+ Add Activity for Day ${currentDay}</button>
      </div>
    `;
    return;
  }

  activities.forEach((act, idx) => {
    const isHighlight = idx === 0;
    const isStaff = act.target_audience === 'Staff only';
    const isDraft = act.status === 'draft';

    const item = document.createElement('div');
    item.className = 'activity-item';
    item.innerHTML = `
      <div class="time-badge ${isHighlight ? 'highlight' : ''}">${escapeHtml(act.start_time)}</div>
      <div class="activity-detail">
        <div class="activity-name">${escapeHtml(act.title)}</div>
        <div style="font-size: 12px; color: var(--color-muted); margin-bottom: 4px;">
          ${escapeHtml(act.venue_name)}${act.end_time ? ` · ends ${escapeHtml(act.end_time)}` : ''}
        </div>
        <span class="audience-pill ${isStaff ? 'staff' : ''}">${escapeHtml(act.target_audience)}</span>
        ${isDraft
          ? '<span class="badge badge-draft" style="margin-left: 4px; padding: 2px 7px; font-size: 10px;">Draft</span>'
          : '<span class="badge badge-subtle" style="margin-left: 4px; padding: 2px 7px; font-size: 10px; background:#E2F0E5; color:#2D4A36;">Published</span>'}
      </div>
      ${isDraft ? `
        <button class="btn-primary-sm" style="padding:5px 10px; font-size:11px;" onclick="quickPublishActivity('${escapeHtml(act.activity_id)}')">Publish</button>
      ` : ''}
      <button class="btn-icon" title="Edit" onclick="openEditActivityModalById('${escapeHtml(act.activity_id)}')">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
      </button>
      <button class="btn-icon danger" title="Delete" onclick="deleteActivity('${escapeHtml(act.activity_id)}')">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
      </button>
    `;
    listEl.appendChild(item);
  });
  runAdminAnime({
    targets: '#activityList .activity-item',
    translateY: [10, 0],
    opacity: [0, 1],
    delay: typeof window.anime === 'function' ? window.anime.stagger(40) : 0,
    duration: 320,
    easing: 'easeOutCubic'
  });
}

async function quickPublishActivity(activityId) {
  try {
    await fetch(`${API_BASE}/api/admin/planner/activity/${encodeURIComponent(activityId)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'published' })
    });
    loadPlanner(currentDay);
    loadDashboard();
  } catch (err) {
    alert('Failed to publish activity: ' + err.message);
  }
}

async function openAddModal() {
  await loadLocationsOptions();
  document.getElementById('activityModalTitle').textContent = `Add Activity to Day ${currentDay}`;
  document.getElementById('editActivityId').value = '';
  document.getElementById('actDay').value = currentDay;
  document.getElementById('actStartTime').value = '08:00';
  document.getElementById('actEndTime').value = '10:00';
  document.getElementById('actTitle').value = '';
  document.getElementById('actVenue').value = '';
  document.getElementById('actAudience').value = 'Everyone';
  document.getElementById('actStatus').value = 'published';
  document.getElementById('actLocationId').value = '';
  document.getElementById('actDescription').value = '';
  document.getElementById('activityModal').classList.add('open');
}

async function openEditActivityModalById(activityId) {
  await loadLocationsOptions();
  const act = adminActivitiesCache.find(a => a.activity_id === activityId);
  if (!act) return;

  document.getElementById('activityModalTitle').textContent = 'Edit Itinerary Activity';
  document.getElementById('editActivityId').value = act.activity_id;
  document.getElementById('actDay').value = act.day_number;
  document.getElementById('actStartTime').value = act.start_time;
  document.getElementById('actEndTime').value = act.end_time || '';
  document.getElementById('actTitle').value = act.title;
  document.getElementById('actVenue').value = act.venue_name;
  document.getElementById('actAudience').value = act.target_audience || 'Everyone';
  document.getElementById('actStatus').value = act.status || 'published';
  document.getElementById('actLocationId').value = act.location_id || '';
  document.getElementById('actDescription').value = act.description || '';
  document.getElementById('activityModal').classList.add('open');
}

function closeActivityModal() {
  document.getElementById('activityModal').classList.remove('open');
}

async function submitActivityForm(e) {
  e.preventDefault();
  const editId = document.getElementById('editActivityId').value;
  const day = parseInt(document.getElementById('actDay').value, 10) || currentDay;
  const dateDay = 17 + day;

  const payload = {
    day_number: day,
    date: `2026-11-${String(dateDay).padStart(2, '0')}`,
    start_time: document.getElementById('actStartTime').value.trim(),
    end_time: document.getElementById('actEndTime').value.trim() || null,
    title: document.getElementById('actTitle').value.trim(),
    venue_name: document.getElementById('actVenue').value.trim(),
    target_audience: document.getElementById('actAudience').value,
    status: document.getElementById('actStatus').value,
    location_id: document.getElementById('actLocationId').value || null,
    description: document.getElementById('actDescription').value.trim() || null
  };

  try {
    const url = editId
      ? `${API_BASE}/api/admin/planner/activity/${encodeURIComponent(editId)}`
      : `${API_BASE}/api/admin/planner/activity`;
    const res = await fetch(url, {
      method: editId ? 'PUT' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Server rejected request');
    }
    closeActivityModal();
    await loadPlanner(day);
    await loadDashboard();
  } catch (err) {
    alert('Failed to save activity: ' + err.message);
  }
}

async function deleteActivity(activityId) {
  if (!confirm(`Are you sure you want to delete activity ${activityId}?`)) return;
  try {
    await fetch(`${API_BASE}/api/admin/planner/activity/${encodeURIComponent(activityId)}`, { method: 'DELETE' });
    await loadPlanner(currentDay);
    await loadDashboard();
  } catch (err) {
    alert('Failed to delete activity: ' + err.message);
  }
}

async function publishDraft() {
  if (!confirm('Publish all itinerary drafts to all student devices?')) return;
  try {
    const res = await fetch(`${API_BASE}/api/admin/planner/publish`, { method: 'POST' });
    const data = await res.json();
    alert(data.message);
    await loadPlanner(currentDay);
    await loadDashboard();
  } catch (err) {
    alert('Error publishing drafts: ' + err.message);
  }
}

async function discardDraft() {
  if (!confirm('Delete all unpublished draft activities and revert to the published schedule?')) return;
  try {
    const res = await fetch(`${API_BASE}/api/admin/planner/discard`, { method: 'DELETE' });
    const data = await res.json();
    alert(data.message);
    await loadPlanner(currentDay);
    await loadDashboard();
  } catch (err) {
    alert('Failed to discard drafts: ' + err.message);
  }
}

// ================= CULTURE MANAGER TAB =================

async function loadCultureList(category = 'All') {
  activeCultureCategory = category;
  document.querySelectorAll('#cultureFilterChips .chip').forEach(c => {
    c.classList.toggle('active', c.textContent.trim() === category);
  });

  try {
    const url = (category === 'All')
      ? `${API_BASE}/api/admin/culture`
      : `${API_BASE}/api/admin/culture?category=${encodeURIComponent(category)}`;
    const res = await fetch(url);
    const articles = res.ok ? await res.json() : [];
    adminCultureCache = articles;
    renderCultureCards(articles);
  } catch (err) {
    console.error('Failed to load culture articles:', err);
  }
}

function filterAdminCulture(cat) {
  loadCultureList(cat);
}

function renderCultureCards(articles) {
  const container = document.getElementById('adminCultureList');
  container.innerHTML = '';

  if (!articles || articles.length === 0) {
    container.innerHTML = `
      <div class="coming-soon-card">
        <div class="cs-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
        </div>
        <div class="cs-title-en">Coming soon</div>
        <div class="cs-title-vi">Sắp ra mắt</div>
        <div class="cs-desc-en">No articles in category "${escapeHtml(activeCultureCategory)}".</div>
        <div class="cs-desc-vi">Chưa có bài viết văn hóa nào trong danh mục này.</div>
        <button class="btn btn-primary-sm" onclick="openAddArticleModal()">+ Add Cultural Article</button>
      </div>
    `;
    return;
  }

  articles.forEach(art => {
    const card = document.createElement('div');
    card.className = 'admin-card';
    card.innerHTML = `
      <div class="admin-card-header">
        <div>
          <h4 class="admin-card-title">${escapeHtml(art.title)}</h4>
          <div style="font-size: 12px; color: var(--color-muted);">
            ${escapeHtml(art.source_title)} (${escapeHtml(art.source_author)}, ${escapeHtml(art.source_date)})
          </div>
        </div>
        <div class="admin-card-actions">
          <button class="btn-icon" title="Edit" onclick="openEditArticleModalById('${escapeHtml(art.content_id)}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
          </button>
          <button class="btn-icon danger" title="Delete" onclick="deleteArticle('${escapeHtml(art.content_id)}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
          </button>
        </div>
      </div>
      <div class="admin-card-body">${escapeHtml(art.summary)}</div>
      <div class="admin-card-meta">
        <span class="tag-cat">${escapeHtml(art.category)}</span>
        <span class="tag-stub">${escapeHtml(art.source_label)}</span>
        <span class="tag-stub">${escapeHtml(art.status)}</span>
        ${art.vietnamese_word ? `<span style="font-size: 12px; font-weight: 700; color: var(--color-clay);">Word: ${escapeHtml(art.vietnamese_word)} (${escapeHtml(art.word_translation || '')})</span>` : ''}
      </div>
    `;
    container.appendChild(card);
  });
}

async function openAddArticleModal() {
  await loadLocationsOptions();
  document.getElementById('cultureModalTitle').textContent = 'Add Cultural Article';
  document.getElementById('editCultureId').value = '';
  document.getElementById('artTitle').value = '';
  document.getElementById('artCategory').value = 'Markets';
  document.getElementById('artSummary').value = '';
  document.getElementById('artContent').value = '';
  document.getElementById('artFact1').value = '';
  document.getElementById('artFact2').value = '';
  document.getElementById('artVietWord').value = '';
  document.getElementById('artTranslation').value = '';
  document.getElementById('artSourceTitle').value = '';
  document.getElementById('artSourceLabel').value = '';
  document.getElementById('artSourceAuthor').value = '';
  document.getElementById('artSourceDate').value = '';
  document.getElementById('artStatus').value = 'published';
  document.getElementById('artLocationId').value = '';
  document.getElementById('cultureModal').classList.add('open');
}

async function openEditArticleModalById(contentId) {
  await loadLocationsOptions();
  const art = adminCultureCache.find(a => a.content_id === contentId);
  if (!art) return;

  document.getElementById('cultureModalTitle').textContent = 'Edit Cultural Article';
  document.getElementById('editCultureId').value = art.content_id;
  document.getElementById('artTitle').value = art.title;
  document.getElementById('artCategory').value = art.category;
  document.getElementById('artSummary').value = art.summary;
  document.getElementById('artContent').value = art.content;
  document.getElementById('artFact1').value = art.fact_1 || '';
  document.getElementById('artFact2').value = art.fact_2 || '';
  document.getElementById('artVietWord').value = art.vietnamese_word || '';
  document.getElementById('artTranslation').value = art.word_translation || '';
  document.getElementById('artSourceTitle').value = art.source_title;
  document.getElementById('artSourceLabel').value = art.source_label;
  document.getElementById('artSourceAuthor').value = art.source_author;
  document.getElementById('artSourceDate').value = art.source_date;
  document.getElementById('artStatus').value = art.status || 'published';
  document.getElementById('artLocationId').value = art.location_id || '';
  document.getElementById('cultureModal').classList.add('open');
}

function closeCultureModal() {
  document.getElementById('cultureModal').classList.remove('open');
}

async function submitCultureForm(e) {
  e.preventDefault();
  const editId = document.getElementById('editCultureId').value;

  const payload = {
    title: document.getElementById('artTitle').value.trim(),
    category: document.getElementById('artCategory').value,
    summary: document.getElementById('artSummary').value.trim(),
    content: document.getElementById('artContent').value.trim(),
    fact_1: document.getElementById('artFact1').value.trim() || null,
    fact_2: document.getElementById('artFact2').value.trim() || null,
    vietnamese_word: document.getElementById('artVietWord').value.trim() || null,
    word_translation: document.getElementById('artTranslation').value.trim() || null,
    source_title: document.getElementById('artSourceTitle').value.trim(),
    source_author: document.getElementById('artSourceAuthor').value.trim(),
    source_date: document.getElementById('artSourceDate').value.trim(),
    source_label: document.getElementById('artSourceLabel').value.trim(),
    location_id: document.getElementById('artLocationId').value || null,
    status: document.getElementById('artStatus').value
  };

  try {
    const url = editId
      ? `${API_BASE}/api/admin/culture/${encodeURIComponent(editId)}`
      : `${API_BASE}/api/admin/culture`;
    const res = await fetch(url, {
      method: editId ? 'PUT' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Server error');
    }
    closeCultureModal();
    await loadCultureList(activeCultureCategory);
    await loadDashboard();
  } catch (err) {
    alert('Failed to save article: ' + err.message);
  }
}

async function deleteArticle(contentId) {
  if (!confirm(`Delete cultural article ${contentId}?`)) return;
  try {
    await fetch(`${API_BASE}/api/admin/culture/${encodeURIComponent(contentId)}`, { method: 'DELETE' });
    await loadCultureList(activeCultureCategory);
    await loadDashboard();
  } catch (err) {
    alert('Failed to delete article: ' + err.message);
  }
}

// ================= LOCATIONS TAB =================

async function loadLocationsList() {
  try {
    const res = await fetch(`${API_BASE}/api/locations`);
    const locs = res.ok ? await res.json() : [];
    adminLocationsCache = locs;
    renderLocations(locs);
  } catch (err) {
    console.error('Failed to load locations:', err);
  }
}

function renderLocations(locs) {
  const container = document.getElementById('adminLocationsList');
  container.innerHTML = '';

  if (!locs || locs.length === 0) {
    container.innerHTML = `
      <div class="coming-soon-card">
        <div class="cs-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"></polygon></svg>
        </div>
        <div class="cs-title-en">Coming soon</div>
        <div class="cs-title-vi">Sắp ra mắt</div>
        <div class="cs-desc-en">No map landmarks have been registered yet.</div>
        <div class="cs-desc-vi">Chưa có địa điểm nào được đăng ký trên bản đồ.</div>
        <button class="btn btn-primary-sm" onclick="openAddLocationModal()">+ Add Location</button>
      </div>
    `;
    return;
  }

  locs.forEach(loc => {
    const card = document.createElement('div');
    card.className = 'admin-card';
    card.innerHTML = `
      <div class="admin-card-header">
        <div>
          <h4 class="admin-card-title">${escapeHtml(loc.name)}</h4>
          <div style="font-size: 12px; color: var(--color-muted);">${escapeHtml(loc.address || '')} · ID: ${escapeHtml(loc.location_id)}</div>
        </div>
        <div class="admin-card-actions">
          <button class="btn-icon" title="Edit" onclick="openEditLocationModalById('${escapeHtml(loc.location_id)}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
          </button>
          <button class="btn-icon danger" title="Delete" onclick="deleteLocation('${escapeHtml(loc.location_id)}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
          </button>
        </div>
      </div>
      <div class="admin-card-body">${escapeHtml(loc.description || '')}</div>
      <div class="admin-card-meta">
        ${loc.latitude !== null ? `<span class="tag-cat">Lat: ${loc.latitude}</span>` : ''}
        ${loc.longitude !== null ? `<span class="tag-cat">Lng: ${loc.longitude}</span>` : ''}
        ${loc.map_reference ? `<span class="tag-stub">${escapeHtml(loc.map_reference)}</span>` : ''}
      </div>
    `;
    container.appendChild(card);
  });
}

function openAddLocationModal() {
  document.getElementById('locationModalTitle').textContent = 'Add Map Location';
  document.getElementById('editLocationMode').value = '';
  const idInput = document.getElementById('locId');
  idInput.value = `LOC-POI-${Date.now().toString().slice(-4)}`;
  idInput.readOnly = false;
  document.getElementById('locName').value = '';
  document.getElementById('locAddress').value = '';
  document.getElementById('locLat').value = '';
  document.getElementById('locLng').value = '';
  document.getElementById('locRef').value = '';
  document.getElementById('locDesc').value = '';
  document.getElementById('locationModal').classList.add('open');
}

function openEditLocationModalById(locId) {
  const loc = adminLocationsCache.find(l => l.location_id === locId);
  if (!loc) return;
  document.getElementById('locationModalTitle').textContent = 'Edit Map Location';
  document.getElementById('editLocationMode').value = loc.location_id;
  const idInput = document.getElementById('locId');
  idInput.value = loc.location_id;
  idInput.readOnly = true;
  document.getElementById('locName').value = loc.name || '';
  document.getElementById('locAddress').value = loc.address || '';
  document.getElementById('locLat').value = loc.latitude ?? '';
  document.getElementById('locLng').value = loc.longitude ?? '';
  document.getElementById('locRef').value = loc.map_reference || '';
  document.getElementById('locDesc').value = loc.description || '';
  document.getElementById('locationModal').classList.add('open');
}

function closeLocationModal() {
  document.getElementById('locationModal').classList.remove('open');
}

async function submitLocationForm(e) {
  e.preventDefault();
  const editLocId = document.getElementById('editLocationMode').value;
  const latRaw = document.getElementById('locLat').value.trim();
  const lngRaw = document.getElementById('locLng').value.trim();

  const payload = {
    location_id: document.getElementById('locId').value.trim(),
    name: document.getElementById('locName').value.trim(),
    address: document.getElementById('locAddress').value.trim() || null,
    latitude: latRaw ? parseFloat(latRaw) : null,
    longitude: lngRaw ? parseFloat(lngRaw) : null,
    map_reference: document.getElementById('locRef').value.trim() || null,
    description: document.getElementById('locDesc').value.trim() || null
  };

  try {
    const url = editLocId
      ? `${API_BASE}/api/admin/locations/${encodeURIComponent(editLocId)}`
      : `${API_BASE}/api/admin/locations`;
    const res = await fetch(url, {
      method: editLocId ? 'PUT' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (res.ok) {
      closeLocationModal();
      await loadLocationsOptions();
      await loadLocationsList();
      await loadDashboard();
    } else {
      const err = await res.json().catch(() => ({}));
      alert('Error saving location: ' + (err.detail || 'Failed'));
    }
  } catch (err) {
    alert('Failed: ' + err.message);
  }
}

async function deleteLocation(locId) {
  if (!confirm(`Delete map location ${locId}?`)) return;
  try {
    await fetch(`${API_BASE}/api/admin/locations/${encodeURIComponent(locId)}`, { method: 'DELETE' });
    await loadLocationsOptions();
    await loadLocationsList();
    await loadDashboard();
  } catch (err) {
    alert('Failed to delete location: ' + err.message);
  }
}

// ================= BROADCAST & APPROVALS TAB =================

async function loadBroadcastNotice() {
  try {
    const res = await fetch(`${API_BASE}/api/broadcast`);
    const data = await res.json();
    const msg = (data.message || '').trim();
    const timeLabel = (data.time_label || '').trim();
    const dayNum = data.day_number || 1;

    document.getElementById('broadcastMsgInput').value = msg;
    document.getElementById('broadcastTimeInput').value = timeLabel;
    document.getElementById('broadcastDayInput').value = dayNum;

    if (msg) {
      document.getElementById('activeBroadcastText').textContent = `"${msg}"`;
      document.getElementById('activeBroadcastMeta').textContent =
        `${timeLabel ? `Time: ${timeLabel} · ` : ''}Active Day ${dayNum} · Live on student devices`;
    } else {
      document.getElementById('activeBroadcastText').textContent = 'No active broadcast · Chưa có thông báo';
      document.getElementById('activeBroadcastMeta').textContent = `Active Day ${dayNum} · Students see "Coming soon"`;
    }
  } catch (err) {
    console.error('Failed to load broadcast notice:', err);
  }
}

async function saveBroadcastNotice() {
  const msg = document.getElementById('broadcastMsgInput').value.trim();
  const time = document.getElementById('broadcastTimeInput').value.trim();
  const day = parseInt(document.getElementById('broadcastDayInput').value, 10) || 1;

  try {
    await fetch(`${API_BASE}/api/admin/broadcast`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: msg, time_label: time, day_number: day })
    });
    alert('Broadcast notice updated live!');
    await loadBroadcastNotice();
    await loadDashboard();
  } catch (err) {
    alert('Failed to update broadcast notice: ' + err.message);
  }
}

async function clearBroadcastNotice() {
  try {
    const day = parseInt(document.getElementById('broadcastDayInput').value, 10) || 1;
    await fetch(`${API_BASE}/api/admin/broadcast`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: '', time_label: '', day_number: day })
    });
    await loadBroadcastNotice();
    await loadDashboard();
  } catch (err) {
    alert('Failed to clear broadcast notice: ' + err.message);
  }
}

async function loadApprovals() {
  try {
    const res = await fetch(`${API_BASE}/api/admin/approvals?status=pending`);
    const pending = res.ok ? await res.json() : [];
    const listEl = document.getElementById('approvalsList');
    listEl.innerHTML = '';

    document.getElementById('navApprovalCount').textContent = String(pending.length);

    if (!pending || pending.length === 0) {
      listEl.innerHTML = `
        <div class="coming-soon-card">
          <div class="cs-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
          </div>
          <div class="cs-title-en">Coming soon · No pending requests</div>
          <div class="cs-title-vi">Chưa có yêu cầu chờ duyệt</div>
          <div class="cs-desc-en">No faculty change proposals are awaiting review.</div>
          <div class="cs-desc-vi">Hiện tại không có đề xuất nào từ giảng viên cần phê duyệt.</div>
        </div>
      `;
      return;
    }

    pending.forEach(app => {
      const card = document.createElement('div');
      card.className = 'admin-card';
      card.innerHTML = `
        <div class="admin-card-header">
          <span style="font-weight: 700; color: var(--color-clay); font-size: 13.5px;">${escapeHtml(app.proposed_by)} · Day ${app.day_number}</span>
          <span class="tag-cat">${escapeHtml(app.proposed_time)}</span>
        </div>
        <h4 class="admin-card-title">${escapeHtml(app.title)}</h4>
        <div class="admin-card-body">${escapeHtml(app.change_description)}</div>
        <div style="display: flex; gap: 8px; margin-top: 10px;">
          <button class="btn btn-primary-sm" onclick="handleApprovalAction(${app.id}, 'approve')">Approve Change</button>
          <button class="btn-icon danger" style="border: 1px solid var(--color-clay); border-radius: 12px; padding: 6px 12px;" onclick="handleApprovalAction(${app.id}, 'reject')">Reject</button>
        </div>
      `;
      listEl.appendChild(card);
    });
  } catch (err) {
    console.error('Failed to load approvals:', err);
  }
}

async function handleApprovalAction(approvalId, action) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/approvals/action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ approval_id: approvalId, action })
    });
    const result = await res.json();
    if (result.status === 'success') {
      alert(`Request has been ${action}d.`);
      await loadApprovals();
      await loadPlanner(currentDay);
      await loadDashboard();
    }
  } catch (err) {
    alert('Failed to update approval action: ' + err.message);
  }
}

// ================= DASHBOARD TAB =================

async function loadDashboard() {
  try {
    const res = await fetch(`${API_BASE}/api/admin/dashboard`);
    const data = await res.json();
    document.getElementById('statTotalActivities').textContent = data.metrics.total_activities;
    document.getElementById('statDayActivities').textContent = `${data.metrics.published_activities} published · ${data.metrics.draft_activities} drafts`;
    document.getElementById('statPendingApprovals').textContent = data.metrics.pending_approvals;
    document.getElementById('statParticipants').textContent = data.metrics.registered_participants;
    document.getElementById('statArticles').textContent = data.metrics.approved_articles;
    document.getElementById('statLocations').textContent = data.metrics.total_locations ?? 0;
    document.getElementById('draftVersionBadge').textContent = data.current_version;

    const pubBtn = document.getElementById('publishBtn');
    const discardBtn = document.getElementById('discardBtn');
    if (pubBtn) {
      if (data.metrics.draft_activities > 0) {
        pubBtn.textContent = `Publish ${data.next_version} (${data.metrics.draft_activities} draft${data.metrics.draft_activities !== 1 ? 's' : ''})`;
        pubBtn.disabled = false;
        pubBtn.style.opacity = '1';
      } else {
        pubBtn.textContent = `All Published (${data.published_version})`;
        pubBtn.disabled = true;
        pubBtn.style.opacity = '0.6';
      }
    }
    if (discardBtn) {
      discardBtn.disabled = data.metrics.draft_activities === 0;
      discardBtn.style.opacity = data.metrics.draft_activities === 0 ? '0.5' : '1';
    }

    document.getElementById('navApprovalCount').textContent = String(data.metrics.pending_approvals);
  } catch (err) {
    console.error('Failed to load admin dashboard:', err);
  }
}

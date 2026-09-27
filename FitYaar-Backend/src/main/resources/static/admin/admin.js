/* FitYaar Management — zero-build super-admin console.
   Served same-origin from the backend (/admin/), so API base defaults to '' (relative /api/...). */
(() => {
  'use strict';

  const LS_TOKEN = 'fy_admin_token', LS_EMAIL = 'fy_admin_email', LS_BASE = 'fy_admin_base', LS_ROLE = 'fy_admin_role';
  let token = localStorage.getItem(LS_TOKEN);
  let adminEmail = localStorage.getItem(LS_EMAIL) || '';

  const $ = (s) => document.querySelector(s);
  const baseUrl = () => (localStorage.getItem(LS_BASE) || '').replace(/\/$/, '');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  const inr = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 });
  const fmtMoney = (paise) => paise ? inr.format(paise / 100) : '₹0';
  const fmtNum = (n) => new Intl.NumberFormat('en-IN').format(n ?? 0);
  const fmtDate = (iso) => iso ? new Date(iso).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';
  const fmtDateTime = (iso) => iso ? new Date(iso).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—';

  function toast(msg, ok) {
    const t = $('#toast');
    t.textContent = msg;
    t.className = 'show ' + (ok ? 'ok' : 'err');
    setTimeout(() => (t.className = ''), 3200);
  }

  async function api(path, { method = 'GET', body } = {}) {
    const res = await fetch(baseUrl() + '/api' + path, {
      method,
      credentials: 'same-origin', // send the httpOnly fy_at cookie for same-origin website sessions
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    const data = text ? JSON.parse(text) : null;
    if (!res.ok) {
      // Session expired/invalid on an authenticated call → drop back to login.
      if (res.status === 401 && token && !path.startsWith('/auth/')) logout();
      const err = new Error((data && data.message) || ('HTTP ' + res.status));
      err.status = res.status;
      throw err;
    }
    return data;
  }

  // ---------------------------------------------------------------- auth

  /** Read the website's readable fy_user cookie (base64url JSON) — set when a super-admin
   *  logs in on the same-origin site. The matching httpOnly fy_at cookie carries auth. */
  function readSessionUser() {
    const c = document.cookie.split('; ').find((x) => x.startsWith('fy_user='));
    if (!c) return null;
    try {
      const b64 = c.slice(8).replace(/-/g, '+').replace(/_/g, '/');
      const bin = atob(b64);
      const bytes = Uint8Array.from(bin, (ch) => ch.charCodeAt(0));
      return JSON.parse(new TextDecoder().decode(bytes));
    } catch (e) { return null; }
  }

  async function doLogin() {
    const email = $('#li-email').value.trim();
    try {
      const d = await api('/auth/login', { method: 'POST', body: { email, password: $('#li-password').value } });
      token = d.accessToken;
      adminEmail = (d.user && d.user.email) || email;
      const role = d.user && d.user.role;
      localStorage.setItem(LS_TOKEN, token);
      localStorage.setItem(LS_EMAIL, adminEmail);
      localStorage.setItem(LS_ROLE, role || '');
      gate(role);
    } catch (e) { toast('Login failed: ' + e.message); }
  }

  async function doClaim() {
    try {
      // Role is read fresh from the DB per request, so the existing token now passes requireSuper.
      await api('/admin/claim', { method: 'POST', body: { code: $('#li-code').value.trim() } });
      localStorage.setItem(LS_ROLE, 'ADMIN');
      toast('You are now super-admin', true);
      enterApp();
    } catch (e) { toast('Claim failed: ' + e.message); }
  }

  /** Role-based gate — no server probe, so no stray 403 in the console. */
  function gate(role) {
    if (role === 'ADMIN') enterApp(); else showDenied();
  }

  function enterApp() {
    $('#login').classList.add('hidden');
    $('#app').classList.remove('hidden');
    $('#who').textContent = adminEmail;
    buildNav();
    if (!location.hash) location.hash = '#/dashboard';
    route();
  }

  /** Signed in, but not the super-admin — role-gated out of the portal. */
  function showDenied() {
    $('#login').classList.remove('hidden');
    $('#app').classList.add('hidden');
    $('#li-form').classList.add('hidden');
    $('#li-denied').classList.remove('hidden');
    $('#li-claim').classList.add('hidden');
  }

  function resetLoginForm() {
    $('#li-email').value = '';
    $('#li-password').value = '';
    if ($('#li-code')) $('#li-code').value = '';
    $('#li-form').classList.remove('hidden');
    $('#li-denied').classList.add('hidden');
    $('#li-claim').classList.add('hidden');
  }

  function logout() {
    token = null;
    localStorage.removeItem(LS_TOKEN);
    localStorage.removeItem(LS_EMAIL);
    localStorage.removeItem(LS_ROLE);
    adminEmail = '';
    closeDrawer();
    $('#app').classList.add('hidden');
    $('#login').classList.remove('hidden');
    resetLoginForm();
  }

  // ---------------------------------------------------------------- nav / routing

  const NAV = [
    { group: 'OVERVIEW', items: [['dashboard', 'Dashboard', '▣']] },
    { group: 'GYM MANAGEMENT', items: [['gyms', 'Gyms', '🏟'], ['users', 'Users', '👤']] },
    { group: 'BUSINESS', items: [['subscriptions', 'Subscriptions', '₹']] },
    { group: 'OPERATIONS', items: [['audit', 'Audit Logs', '📜']] },
    { group: 'PLATFORM', items: [['settings', 'Settings', '⚙']] },
  ];
  const TITLES = { dashboard: 'Dashboard', gyms: 'Gyms', users: 'Users', subscriptions: 'Subscriptions', audit: 'Audit Logs', settings: 'Settings' };

  function buildNav() {
    $('#nav').innerHTML = NAV.map((g) =>
      `<div class="navgroup">${g.group}</div>` +
      g.items.map(([id, label, ico]) =>
        `<div class="navlink" data-route="${id}"><span class="ico">${ico}</span>${label}</div>`).join('')
    ).join('');
    $('#nav').querySelectorAll('.navlink').forEach((n) =>
      n.onclick = () => { location.hash = '#/' + n.dataset.route; });
  }

  function route() {
    closeDrawer();                 // don't leave a detail drawer covering the next page
    const id = (location.hash.replace('#/', '') || 'dashboard');
    const page = RENDER[id] ? id : 'dashboard';
    $('#page-title').textContent = TITLES[page];
    $('#nav').querySelectorAll('.navlink').forEach((n) =>
      n.classList.toggle('active', n.dataset.route === page));
    RENDER[page]();
    const main = document.querySelector('.main');
    if (main) main.scrollTop = 0;
    window.scrollTo(0, 0);
  }

  // ---------------------------------------------------------------- helpers

  const view = (html) => { $('#view').innerHTML = html; };
  const statusBadge = (s) => {
    const map = { ACTIVE: 'b-active', PENDING: 'b-warn', INVITED: 'b-warn', SUSPENDED: 'b-bad',
      DEACTIVATED: 'b-bad', REJECTED: 'b-bad', INACTIVE: 'b-neutral', EXPIRED: 'b-bad', CANCELLED: 'b-neutral' };
    return `<span class="badge ${map[s] || 'b-neutral'}">${esc(s || '—')}</span>`;
  };

  function sparkline(points, color) {
    if (!points || !points.length) return '<div class="muted">No data</div>';
    const vals = points.map((p) => p.count);
    const max = Math.max(1, ...vals), n = points.length, W = 600, H = 60;
    const step = n > 1 ? W / (n - 1) : W;
    const path = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${(i * step).toFixed(1)},${(H - (p.count / max) * (H - 6) - 3).toFixed(1)}`).join(' ');
    const total = vals.reduce((a, b) => a + b, 0);
    return `<div class="chartwrap"><svg class="chart" viewBox="0 0 ${W} ${H}" preserveAspectRatio="none">
      <path d="${path}" fill="none" stroke="${color}" stroke-width="2"/></svg>
      <div class="muted" style="font-size:12px">${fmtNum(total)} total over ${n} days</div></div>`;
  }

  function drawer(html) {
    closeDrawer();
    const s = document.createElement('div'); s.className = 'scrim'; s.id = 'scrim'; s.onclick = closeDrawer;
    const d = document.createElement('div'); d.className = 'drawer'; d.id = 'drawer';
    d.innerHTML = `<button class="close sm" onclick="">Close</button>` + html;
    document.body.appendChild(s); document.body.appendChild(d);
    d.querySelector('.close').onclick = closeDrawer;
    return d;
  }
  function closeDrawer() { ['scrim', 'drawer'].forEach((id) => { const e = document.getElementById(id); if (e) e.remove(); }); }

  function pager(pageObj, onGo) {
    if (!pageObj) return '';
    const { number, totalPages, totalElements } = pageObj;
    const wrap = document.createElement('div'); wrap.className = 'pager';
    wrap.innerHTML = `<span class="muted">${fmtNum(totalElements)} total · page ${number + 1}/${Math.max(1, totalPages)}</span>`;
    const prev = document.createElement('button'); prev.className = 'ghost sm'; prev.textContent = 'Prev';
    prev.disabled = pageObj.first; prev.onclick = () => onGo(number - 1);
    const next = document.createElement('button'); next.className = 'ghost sm'; next.textContent = 'Next';
    next.disabled = pageObj.last; next.onclick = () => onGo(number + 1);
    wrap.appendChild(prev); wrap.appendChild(next);
    return wrap;
  }

  // ---------------------------------------------------------------- Dashboard

  async function renderDashboard() {
    view('<div class="muted">Loading platform overview…</div>');
    let o, signups, workouts;
    try {
      [o, signups, workouts] = await Promise.all([
        api('/admin/metrics/overview'),
        api('/admin/metrics/timeseries?metric=signups&days=30'),
        api('/admin/metrics/timeseries?metric=workouts&days=30'),
      ]);
    } catch (e) { view(`<div class="card">Failed to load: ${esc(e.message)}</div>`); return; }

    const kpi = (v, l, sub) => `<div class="kpi"><div class="v">${v}</div><div class="l">${l}</div>${sub ? `<div class="sub">${sub}</div>` : ''}</div>`;
    const alerts = [];
    if (o.gymsOverCap) alerts.push(['bad', `${o.gymsOverCap} gym(s) over paid-seat cap — upsell a higher tier`]);
    if (o.plansExpiringSoon) alerts.push(['warn', `${o.plansExpiringSoon} gym plan(s) expiring within 14 days`]);
    if (o.subsExpiringSoon) alerts.push(['warn', `${o.subsExpiringSoon} Pro subscription(s) expiring within 14 days`]);
    if (o.suspendedUsers) alerts.push(['warn', `${o.suspendedUsers} suspended user account(s)`]);
    if (!alerts.length) alerts.push(['ok', 'All clear — no gyms over cap, no imminent expiries']);

    const breakdown = (obj) => Object.keys(obj || {}).length
      ? Object.entries(obj).map(([k, v]) => `<code>${esc(k)}: ${v}</code>`).join(' ')
      : '<span class="muted">none</span>';

    view(`
      <div class="kpis">
        ${kpi(fmtNum(o.totalGyms), 'Gyms', `${fmtNum(o.gymsWithActivePlan)} on active plan`)}
        ${kpi(fmtNum(o.totalUsers), 'Users', `${fmtNum(o.activeUsers)} active`)}
        ${kpi(fmtNum(o.activeMembers), 'Gym members', `${fmtNum(o.totalTrainers)} trainers · ${fmtNum(o.totalOwners)} owners`)}
        ${kpi(fmtNum(o.liveCheckins), 'Live check-ins', 'right now')}
        ${kpi(fmtMoney(o.estimatedMrrPaise), 'Est. MRR', 'advisory · from config prices')}
        ${kpi(fmtNum(o.activeProSubscribers), 'Pro subscribers', `${fmtNum(o.workouts7d)} workouts / 7d`)}
      </div>
      <div class="row">
        <div class="card"><h3>New signups · 30 days</h3>${sparkline(signups, '#ff7043')}</div>
        <div class="card"><h3>Workouts logged · 30 days</h3>${sparkline(workouts, '#8bc34a')}</div>
      </div>
      <div class="row">
        <div class="card"><h3>Needs attention</h3>
          ${alerts.map(([d, t]) => `<div class="alertline"><span class="dot ${d}"></span>${esc(t)}</div>`).join('')}
        </div>
        <div class="card"><h3>Subscriptions</h3>
          <div class="kv">
            <div class="k">By plan</div><div>${breakdown(o.subsByPlan)}</div>
            <div class="k">By source</div><div>${breakdown(o.subsBySource)}</div>
            <div class="k">Workouts total</div><div>${fmtNum(o.totalWorkouts)}</div>
            <div class="k">Workouts 24h</div><div>${fmtNum(o.workouts24h)}</div>
          </div>
        </div>
      </div>`);
  }

  // ---------------------------------------------------------------- Gyms

  async function renderGyms() {
    view('<div class="muted">Loading gyms…</div>');
    let gyms;
    try { gyms = await api('/admin/gyms'); } catch (e) { view(`<div class="card">Failed: ${esc(e.message)}</div>`); return; }

    const rows = gyms.map((g) => `
      <tr class="click" data-gym="${g.id}">
        <td>${g.id}</td><td>${esc(g.name)}</td>
        <td><code>${esc(g.joinCode)}</code></td>
        <td>${g.planTier ? `<code>${esc(g.planTier)}</code>` : '<span class="muted">—</span>'}</td>
        <td>${g.planStatus ? statusBadge(g.planStatus) : '<span class="muted">—</span>'}</td>
        <td>${g.paidSeats ?? '<span class="muted">∞</span>'}</td>
      </tr>`).join('');

    view(`
      <div class="card">
        <h3>Create gym</h3>
        <div class="row">
          <div><label>Name</label><input id="g-name" placeholder="Iron Temple" /></div>
          <div><label>Capacity</label><input id="g-cap" type="number" value="100" /></div>
        </div>
        <div class="row">
          <div><label>Join code</label><input id="g-join" placeholder="IRON123" /></div>
          <div><label>Owner code</label><input id="g-owner" placeholder="OWNER123" /></div>
        </div>
        <div style="margin-top:12px"><button id="g-create">Create gym</button></div>
      </div>
      <div class="card">
        <h3>All gyms (${gyms.length})</h3>
        <table><thead><tr><th>ID</th><th>Name</th><th>Join</th><th>Tier</th><th>Plan</th><th>Seats</th></tr></thead>
          <tbody>${rows || '<tr><td colspan="6" class="muted">No gyms yet</td></tr>'}</tbody></table>
      </div>`);

    $('#g-create').onclick = async () => {
      try {
        await api('/admin/gyms', { method: 'POST', body: {
          name: $('#g-name').value.trim(), capacity: parseInt($('#g-cap').value || '0', 10),
          joinCode: $('#g-join').value.trim(), ownerCode: $('#g-owner').value.trim() } });
        toast('Gym created', true); renderGyms();
      } catch (e) { toast('Create failed: ' + e.message); }
    };
    $('#view').querySelectorAll('tr[data-gym]').forEach((tr) =>
      tr.onclick = () => gymDrawer(gyms.find((x) => x.id == tr.dataset.gym)));
  }

  async function gymDrawer(g) {
    const d = drawer(`<h3>${esc(g.name)}</h3><div class="muted">Gym #${g.id}</div><div id="gd-body">Loading…</div>`);
    let members = [], seats = null;
    try { [members, seats] = await Promise.all([
      api('/admin/gyms/' + g.id + '/members'),
      api('/admin/gyms/' + g.id + '/seats')]); } catch (e) { toast(e.message); }

    const memberRows = members.map((m) =>
      `<tr><td>${esc(m.displayName || m.email)}</td><td>${esc(m.role)}</td><td>${statusBadge(m.status)}</td></tr>`).join('');

    d.querySelector('#gd-body').innerHTML = `
      <div class="kv">
        <div class="k">Join code</div><div><code>${esc(g.joinCode)}</code></div>
        <div class="k">Owner code</div><div><code>${esc(g.ownerCode)}</code></div>
        <div class="k">Capacity</div><div>${g.capacity ?? '—'}</div>
        <div class="k">Seats</div><div>${seats ? `${seats.activeMembers} active / ${seats.paidSeats ?? '∞'} paid ${seats.overCap ? '<span class="badge b-bad">OVER CAP</span>' : ''}` : '—'}</div>
        <div class="k">Plan</div><div>${g.planTier ? `<code>${esc(g.planTier)}</code> ${statusBadge(g.planStatus)}` : '<span class="muted">no plan</span>'}</div>
        <div class="k">Valid until</div><div>${fmtDateTime(g.planCurrentPeriodEnd)}</div>
      </div>
      <div class="card" style="margin-top:6px"><h3>Assign owner</h3>
        <div class="row"><input id="gd-owner-email" placeholder="owner@example.com" />
        <button class="ghost" id="gd-assign" style="flex:0 0 auto">Assign</button></div>
      </div>
      <div class="card"><h3>Billing plan</h3>
        <div class="row">
          <div><label>Tier</label><select id="gd-tier">${tierOptions(g.planTier)}</select></div>
          <div><label>Status</label><select id="gd-status">
            <option value="">(none)</option>${['ACTIVE', 'SUSPENDED', 'EXPIRED'].map((s) =>
              `<option ${g.planStatus === s ? 'selected' : ''}>${s}</option>`).join('')}</select></div>
        </div>
        <div class="row">
          <div><label>Paid seats</label><input id="gd-seats" type="number" value="${g.paidSeats ?? ''}" /></div>
          <div><label>Valid until</label><input id="gd-until" type="datetime-local" /></div>
        </div>
        <div style="margin-top:10px"><button id="gd-save">Save plan</button></div>
      </div>
      <div class="card"><h3>Members (${members.length})</h3>
        <table><thead><tr><th>Member</th><th>Role</th><th>Status</th></tr></thead>
          <tbody>${memberRows || '<tr><td colspan="3" class="muted">No members</td></tr>'}</tbody></table>
      </div>`;

    d.querySelector('#gd-assign').onclick = async () => {
      try { await api('/admin/gyms/' + g.id + '/admins', { method: 'POST', body: { email: d.querySelector('#gd-owner-email').value.trim() } });
        toast('Owner assigned', true); gymDrawer(g); } catch (e) { toast('Assign failed: ' + e.message); }
    };
    d.querySelector('#gd-save').onclick = async () => {
      const until = d.querySelector('#gd-until').value;
      try {
        const updated = await api('/admin/gyms/' + g.id + '/plan', { method: 'POST', body: {
          planTier: d.querySelector('#gd-tier').value.trim() || null,
          planStatus: d.querySelector('#gd-status').value || null,
          planCurrentPeriodEnd: until || null,
          paidSeats: d.querySelector('#gd-seats').value ? parseInt(d.querySelector('#gd-seats').value, 10) : null } });
        toast('Plan saved', true); gymDrawer(updated); renderGyms();
      } catch (e) { toast('Save failed: ' + e.message); }
    };
  }

  // ---------------------------------------------------------------- Users

  const usersState = { q: '', role: '', status: '', page: 0 };

  async function renderUsers() {
    view(`
      <div class="card">
        <div class="toolbar">
          <div class="grow"><label>Search</label><input id="u-q" placeholder="email or name" value="${esc(usersState.q)}" /></div>
          <div><label>Role</label><select id="u-role">${opt(['', 'USER', 'PREMIUM', 'ADMIN'], usersState.role)}</select></div>
          <div><label>Status</label><select id="u-status">${opt(['', 'ACTIVE', 'INVITED', 'SUSPENDED', 'DEACTIVATED'], usersState.status)}</select></div>
          <div><button id="u-go">Filter</button></div>
        </div>
        <div id="u-table" class="muted">Loading…</div>
        <div id="u-pager"></div>
      </div>`);
    $('#u-go').onclick = () => { usersState.q = $('#u-q').value.trim(); usersState.role = $('#u-role').value;
      usersState.status = $('#u-status').value; usersState.page = 0; loadUsers(); };
    $('#u-q').onkeydown = (e) => { if (e.key === 'Enter') $('#u-go').click(); };
    loadUsers();
  }

  async function loadUsers() {
    try {
      const qs = `?q=${encodeURIComponent(usersState.q)}&role=${usersState.role}&status=${usersState.status}&page=${usersState.page}&size=25`;
      const p = await api('/admin/users' + qs);
      const rows = p.content.map((u) => `
        <tr class="click" data-uid="${u.id}">
          <td>${esc(u.displayName || '—')}</td><td>${esc(u.email)}</td>
          <td>${esc(u.role || 'USER')}</td><td>${statusBadge(u.status)}</td><td>${fmtDate(u.createdAt)}</td>
        </tr>`).join('');
      $('#u-table').innerHTML = `<table><thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="5" class="muted">No users</td></tr>'}</tbody></table>`;
      const pg = pager(p, (n) => { usersState.page = n; loadUsers(); });
      const pw = $('#u-pager'); pw.innerHTML = ''; if (pg) pw.appendChild(pg);
      $('#u-table').querySelectorAll('tr[data-uid]').forEach((tr) => tr.onclick = () => userDrawer(tr.dataset.uid));
    } catch (e) { $('#u-table').innerHTML = `<div class="muted">Failed: ${esc(e.message)}</div>`; }
  }

  async function userDrawer(id) {
    const d = drawer('<div id="ud">Loading…</div>');
    let u;
    try { u = await api('/admin/users/' + id); } catch (e) { d.querySelector('#ud').innerHTML = esc(e.message); return; }
    const gyms = (u.memberships || []).map((m) =>
      `<tr><td>${esc(m.gymName || ('Gym #' + m.gymId))}</td><td>${esc(m.role)}</td><td>${statusBadge(m.status)}</td></tr>`).join('');
    d.querySelector('#ud').innerHTML = `
      <h3>${esc(u.displayName || u.email)}</h3>
      <div class="muted">${esc(u.email)} · ${esc(u.role || 'USER')} ${statusBadge(u.status)}</div>
      <div class="kv">
        <div class="k">Joined</div><div>${fmtDateTime(u.createdAt)}</div>
        <div class="k">Pro</div><div>${u.pro ? `<span class="badge b-active">PRO</span> ${esc(u.plan || '')} · ${esc(u.source || '')}${u.proUntil ? ' · until ' + fmtDate(u.proUntil) : ''}` : '<span class="muted">free</span>'}</div>
        <div class="k">Workouts</div><div>${fmtNum(u.workoutCount)}</div>
        <div class="k">Phone</div><div>${esc(u.phone || '—')}</div>
        <div class="k">Goal</div><div>${esc(u.fitnessGoal || '—')}</div>
      </div>
      <div class="card"><h3>Actions</h3>
        <div class="row">
          <button class="ghost sm" data-act="reactivate">Reactivate</button>
          <button class="danger sm" data-act="suspend">Suspend</button>
          <button class="danger sm" data-act="deactivate">Deactivate</button>
        </div>
        <div class="row" style="margin-top:10px">
          <select id="ud-plan">${opt(['MONTHLY', 'YEARLY', 'LIFETIME'], 'YEARLY')}</select>
          <button class="sm" id="ud-grant" style="flex:0 0 auto">Grant Pro</button>
        </div>
      </div>
      <div class="card"><h3>Gym memberships (${(u.memberships || []).length})</h3>
        <table><thead><tr><th>Gym</th><th>Role</th><th>Status</th></tr></thead>
          <tbody>${gyms || '<tr><td colspan="3" class="muted">None</td></tr>'}</tbody></table>
      </div>`;
    d.querySelectorAll('button[data-act]').forEach((b) => b.onclick = async () => {
      try { await api('/admin/users/' + b.dataset.act, { method: 'POST', body: { email: u.email } });
        toast('Done: ' + b.dataset.act, true); userDrawer(id); loadUsers(); } catch (e) { toast(e.message); }
    });
    d.querySelector('#ud-grant').onclick = async () => {
      try { await api('/subscriptions/grant', { method: 'POST', body: { email: u.email, plan: d.querySelector('#ud-plan').value } });
        toast('Pro granted', true); userDrawer(id); } catch (e) { toast('Grant failed: ' + e.message); }
    };
  }

  // ---------------------------------------------------------------- Subscriptions

  const subState = { status: '', source: '', plan: '', q: '', page: 0 };

  async function renderSubscriptions() {
    view(`
      <div class="card"><h3>Grant Pro</h3>
        <div class="row">
          <div class="grow"><label>User email</label><input id="s-email" placeholder="user@example.com" /></div>
          <div><label>Plan</label><select id="s-plan">${opt(['MONTHLY', 'YEARLY', 'LIFETIME'], 'YEARLY')}</select></div>
          <div><button id="s-grant">Grant</button></div>
        </div>
      </div>
      <div class="card">
        <div class="toolbar">
          <div class="grow"><label>Search</label><input id="s-q" placeholder="email or name" value="${esc(subState.q)}" /></div>
          <div><label>Status</label><select id="s-status">${opt(['', 'ACTIVE', 'CANCELLED', 'EXPIRED'], subState.status)}</select></div>
          <div><label>Source</label><select id="s-source">${opt(['', 'RAZORPAY', 'MANUAL', 'PROMO'], subState.source)}</select></div>
          <div><label>Plan</label><select id="s-planf">${opt(['', 'MONTHLY', 'YEARLY', 'LIFETIME'], subState.plan)}</select></div>
          <div><button id="s-go">Filter</button></div>
        </div>
        <div id="s-table" class="muted">Loading…</div>
        <div id="s-pager"></div>
      </div>`);
    $('#s-grant').onclick = async () => {
      try { await api('/subscriptions/grant', { method: 'POST', body: { email: $('#s-email').value.trim(), plan: $('#s-plan').value } });
        toast('Pro granted', true); loadSubs(); } catch (e) { toast('Grant failed: ' + e.message); }
    };
    $('#s-go').onclick = () => { subState.q = $('#s-q').value.trim(); subState.status = $('#s-status').value;
      subState.source = $('#s-source').value; subState.plan = $('#s-planf').value; subState.page = 0; loadSubs(); };
    loadSubs();
  }

  async function loadSubs() {
    try {
      const qs = `?status=${subState.status}&source=${subState.source}&plan=${subState.plan}&q=${encodeURIComponent(subState.q)}&page=${subState.page}&size=25`;
      const p = await api('/admin/subscriptions' + qs);
      const rows = p.content.map((s) => `
        <tr><td>${esc(s.displayName || s.email)}</td><td>${esc(s.plan)}</td><td>${esc(s.source)}</td>
          <td>${statusBadge(s.status)}</td><td>${s.currentPeriodEnd ? fmtDate(s.currentPeriodEnd) : '<span class="muted">never</span>'}</td>
          <td>${fmtDate(s.createdAt)}</td></tr>`).join('');
      $('#s-table').innerHTML = `<table><thead><tr><th>User</th><th>Plan</th><th>Source</th><th>Status</th><th>Ends</th><th>Granted</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="6" class="muted">No subscriptions</td></tr>'}</tbody></table>`;
      const pg = pager(p, (n) => { subState.page = n; loadSubs(); });
      const pw = $('#s-pager'); pw.innerHTML = ''; if (pg) pw.appendChild(pg);
    } catch (e) { $('#s-table').innerHTML = `<div class="muted">Failed: ${esc(e.message)}</div>`; }
  }

  // ---------------------------------------------------------------- Audit

  const auditState = { action: '', page: 0 };

  async function renderAudit() {
    view(`
      <div class="card">
        <div class="toolbar">
          <div><label>Action</label><select id="a-action">${opt(['', 'CLAIM_SUPER', 'CREATE_GYM', 'ASSIGN_OWNER', 'PLAN_CHANGED', 'USER_STATUS_CHANGED', 'SUBSCRIPTION_GRANTED', 'PROMO_REDEEMED'], auditState.action)}</select></div>
          <div><button id="a-go">Filter</button></div>
        </div>
        <div id="a-table" class="muted">Loading…</div>
        <div id="a-pager"></div>
      </div>`);
    $('#a-go').onclick = () => { auditState.action = $('#a-action').value; auditState.page = 0; loadAudit(); };
    loadAudit();
  }

  async function loadAudit() {
    try {
      const p = await api(`/admin/audit?action=${auditState.action}&page=${auditState.page}&size=50`);
      const rows = p.content.map((a) => `
        <tr><td>${fmtDateTime(a.createdAt)}</td><td>${esc(a.actorEmail || 'system')}</td>
          <td><code>${esc(a.action)}</code></td>
          <td>${esc(a.resourceType || '')} ${a.resourceId ? esc(a.resourceId) : ''}</td>
          <td>${a.metadata ? `<span class="muted">${esc(a.metadata)}</span>` : ''}</td>
          <td class="muted">${esc(a.ip || '')}</td></tr>`).join('');
      $('#a-table').innerHTML = `<table><thead><tr><th>Time</th><th>Actor</th><th>Action</th><th>Resource</th><th>Details</th><th>IP</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="6" class="muted">No audit entries</td></tr>'}</tbody></table>`;
      const pg = pager(p, (n) => { auditState.page = n; loadAudit(); });
      const pw = $('#a-pager'); pw.innerHTML = ''; if (pg) pw.appendChild(pg);
    } catch (e) { $('#a-table').innerHTML = `<div class="muted">Failed: ${esc(e.message)}</div>`; }
  }

  // ---------------------------------------------------------------- Settings

  function renderSettings() {
    view(`
      <div class="card"><h3>Connection</h3>
        <label>API base URL (blank = same origin as this page)</label>
        <input id="set-base" value="${esc(localStorage.getItem(LS_BASE) || '')}" placeholder="(same origin)" />
        <div style="margin-top:10px"><button id="set-save">Save</button></div>
        <div class="muted" style="margin-top:8px">Signed in as <b>${esc(adminEmail)}</b></div>
      </div>
      <div class="card"><h3>Super-admin claim</h3>
        <div class="muted">One-time bootstrap of a new super-admin account (server env <code>SUPER_ADMIN_CODE</code>).</div>
        <div class="row" style="margin-top:8px"><input id="set-code" placeholder="claim code" />
          <button class="ghost" id="set-claim" style="flex:0 0 auto">Claim</button></div>
      </div>
      <div class="card"><h3>About</h3>
        <div class="muted">FitYaar Management · Platform Operations &amp; Administration.
        Payments are recorded manually today (live Razorpay + transaction ledger land in a later phase).</div>
      </div>`);
    $('#set-save').onclick = () => { localStorage.setItem(LS_BASE, $('#set-base').value.trim()); toast('Saved', true); };
    $('#set-claim').onclick = async () => {
      try { await api('/admin/claim', { method: 'POST', body: { code: $('#set-code').value.trim() } }); toast('Claimed', true); }
      catch (e) { toast('Claim failed: ' + e.message); }
    };
  }

  const opt = (values, selected) => values.map((v) =>
    `<option value="${v}" ${v === selected ? 'selected' : ''}>${v === '' ? 'All' : v}</option>`).join('');

  /** Tier dropdown options (config price map keys), keeping any custom existing value. */
  const tierOptions = (current) => {
    const tiers = ['', 'STARTER', 'GROWTH', 'PRO'];
    if (current && !tiers.includes(current)) tiers.push(current);
    return tiers.map((t) =>
      `<option value="${esc(t)}" ${t === (current || '') ? 'selected' : ''}>${t === '' ? '(none)' : esc(t)}</option>`).join('');
  };

  const RENDER = { dashboard: renderDashboard, gyms: renderGyms, users: renderUsers,
    subscriptions: renderSubscriptions, audit: renderAudit, settings: renderSettings };

  // ---------------------------------------------------------------- boot

  $('#li-btn').onclick = doLogin;
  $('#li-password').onkeydown = (e) => { if (e.key === 'Enter') doLogin(); };
  $('#li-claim-btn').onclick = doClaim;
  $('#li-claim-link').onclick = () => $('#li-claim').classList.toggle('hidden');
  $('#li-back').onclick = () => { token = null; localStorage.removeItem(LS_TOKEN); resetLoginForm(); };
  $('#logout').onclick = logout;
  window.addEventListener('hashchange', route);

  if (token) {
    gate(localStorage.getItem(LS_ROLE));
  } else {
    // No localStorage token → try a same-origin website cookie session (httpOnly fy_at carries auth).
    const su = readSessionUser();
    if (su && su.role === 'ADMIN') { adminEmail = su.email || ''; enterApp(); }
    else resetLoginForm();
  }
})();

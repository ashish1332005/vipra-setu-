const baseUrl = process.env.API_BASE_URL || 'http://127.0.0.1:5000/api';
const roles = [
  { name: 'admin', phone: process.env.ADMIN_PHONE || '0000000000', password: process.env.ADMIN_PASSWORD || 'localAdmin12345!' },
  { name: 'service_provider', phone: process.env.DEV_PROVIDER_PHONE || '9521066616', password: process.env.DEV_PROVIDER_PASSWORD || '1234567890' },
  { name: 'service_taker', phone: process.env.DEV_TAKER_PHONE || '9521066617', password: process.env.DEV_TAKER_PASSWORD || '1234567890' },
];
const request = async (path, options = {}) => {
  const response = await fetch(`${baseUrl}${path}`, { headers: { 'content-type': 'application/json', ...(options.token ? { authorization: `Bearer ${options.token}` } : {}) }, ...options, body: options.body ? JSON.stringify(options.body) : undefined });
  return { status: response.status, body: await response.json().catch(() => ({})) };
};
const fail = (message) => { throw new Error(message); };
(async () => {
  const sessions = {};
  for (const role of roles) {
    const login = await request('/auth/login', { method: 'POST', body: { phone: role.phone, password: role.password } });
    if (login.status !== 200 || !login.body.token) fail(`${role.name} login failed (${login.status})`);
    if (login.body.user?.role !== role.name) fail(`${role.name} role mismatch`);
    sessions[role.name] = login.body.token;
    const me = await request('/auth/me', { token: login.body.token });
    if (me.status !== 200) fail(`${role.name} /auth/me failed (${me.status})`);
  }
  const categories = await request('/categories');
  if (categories.status !== 200 || !Array.isArray(categories.body.categories) || categories.body.categories.length === 0) fail(`categories failed (${categories.status})`);
  if ((await request('/admin/dashboard', { token: sessions.admin })).status !== 200) fail('admin dashboard failed');
  if ((await request('/providers/me/requests', { token: sessions.service_provider })).status !== 200) fail('provider requests failed');
  if ((await request('/service-takers/me/requests', { token: sessions.service_taker })).status !== 200) fail('service-taker requests failed');
  const created = await request('/service-takers/me/requests', { method: 'POST', token: sessions.service_taker, body: { category: 'Electrician', title: 'Role smoke booking', description: 'Automated local smoke request', city: 'Bhilwara', address: 'Local test address' } });
  if (created.status !== 201 || !created.body.request?._id) fail('booking create failed (' + created.status + ')');
  if ((await request('/providers/me/open-requests', { token: sessions.service_provider })).status !== 200) fail('provider open requests failed');
  const requestId = created.body.request._id;
  const claim = await request('/providers/me/open-requests/' + requestId + '/claim', { method: 'PATCH', token: sessions.service_provider });
  if (claim.status !== 200) fail('provider claim failed (' + claim.status + ')');
  const quote = await request('/providers/me/requests/' + requestId + '/quote', { method: 'POST', token: sessions.service_provider, body: { amount: 750, priceLabel: '₹750', scope: 'Role smoke test service' } });
  if (quote.status !== 200) fail('provider quote failed (' + quote.status + ')');
  const accept = await request('/service-takers/me/requests/' + requestId + '/quote', { method: 'PATCH', token: sessions.service_taker, body: { status: 'accepted' } });
  if (accept.status !== 200) fail('quote acceptance failed (' + accept.status + ')');
  for (const status of ['in_progress', 'completed']) {
    const update = await request('/providers/me/requests/' + requestId + '/status', { method: 'PATCH', token: sessions.service_provider, body: { status: status, note: 'Role smoke lifecycle' } });
    if (update.status !== 200) fail('provider status ' + status + ' failed (' + update.status + ')');
  }
  if ((await request('/admin/requests', { token: sessions.admin })).status !== 200) fail('admin requests failed');
  const review = await request('/service-takers/me/reviews', { method: 'POST', token: sessions.service_taker, body: { request: requestId, rating: 5, comment: 'Role smoke review' } });
  if (review.status !== 201) fail('review submission failed (' + review.status + ')');
  const rejected = await request('/service-takers/me/requests', { method: 'POST', token: sessions.service_taker, body: { category: 'Electrician', title: 'Role smoke reject quote', description: 'Automated reject quote request', city: 'Bhilwara', address: 'Local test address' } });
  if (rejected.status !== 201 || !rejected.body.request?._id) fail('reject booking create failed (' + rejected.status + ')');
  const rejectedId = rejected.body.request._id;
  if ((await request('/providers/me/open-requests/' + rejectedId + '/claim', { method: 'PATCH', token: sessions.service_provider })).status !== 200) fail('reject flow claim failed');
  if ((await request('/providers/me/requests/' + rejectedId + '/quote', { method: 'POST', token: sessions.service_provider, body: { amount: 900, priceLabel: '₹900', scope: 'Reject quote smoke test' } })).status !== 200) fail('reject flow quote failed');
  const reject = await request('/service-takers/me/requests/' + rejectedId + '/quote', { method: 'PATCH', token: sessions.service_taker, body: { status: 'rejected' } });
  if (reject.status !== 200) fail('quote rejection failed (' + reject.status + ')');
  const rejectedCleanup = await request('/service-takers/me/requests/' + rejectedId, { method: 'DELETE', token: sessions.service_taker });
  if (rejectedCleanup.status !== 200) fail('rejected booking cleanup failed');
  const cleanup = await request('/service-takers/me/requests/' + requestId, { method: 'DELETE', token: sessions.service_taker });
  if (cleanup.status !== 200) fail('booking cleanup failed (' + cleanup.status + ')');
  if ((await request('/admin/dashboard', { token: sessions.service_taker })).status !== 403) fail('role protection failed');
  console.log(`Role smoke passed: ${categories.body.categories.length} categories; admin/provider/taker protected flows OK.`);
})().catch((error) => { console.error(`Role smoke failed: ${error.message}`); process.exitCode = 1; });

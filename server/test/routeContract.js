const assert = require('assert');

const routers = {
  auth: require('../routes/authRoutes'),
  admin: require('../routes/adminRoutes'),
  providers: require('../routes/providerRoutes'),
  'service-takers': require('../routes/serviceTakerRoutes'),
  services: require('../routes/serviceRoutes'),
  notifications: require('../routes/notificationRoutes'),
  ads: require('../routes/adRoutes'),
  categories: require('../routes/categoryRoutes'),
};

const routes = new Set();
for (const [prefix, router] of Object.entries(routers)) {
  for (const layer of router.stack) {
    if (!layer.route) continue;
    for (const method of Object.keys(layer.route.methods)) {
      routes.add(`${method.toUpperCase()} /${prefix}${layer.route.path === '/' ? '' : layer.route.path}`);
    }
  }
}

const flutterContracts = [
  'POST /auth/register', 'POST /auth/login', 'POST /auth/forgot-password',
  'POST /auth/reset-password', 'GET /auth/me', 'PATCH /auth/me',
  'PATCH /auth/password', 'GET /categories', 'GET /ads',
  'GET /notifications', 'PATCH /notifications/:id/read',
  'GET /providers', 'GET /providers/me', 'PUT /providers/me',
  'GET /providers/me/analytics', 'GET /providers/me/services',
  'POST /providers/me/services', 'PATCH /providers/me/services/:id',
  'DELETE /providers/me/services/:id', 'PATCH /providers/me/location',
  'GET /providers/me/requests', 'GET /providers/me/open-requests',
  'GET /providers/me/contact-logs', 'PATCH /providers/me/open-requests/:id/claim',
  'PATCH /providers/me/requests/:id/status',
  'GET /service-takers/me/requests', 'POST /service-takers/me/requests',
  'PUT /service-takers/me/requests/:id', 'DELETE /service-takers/me/requests/:id',
  'PATCH /service-takers/me/requests/:id/quote', 'POST /service-takers/me/reviews',
  'POST /service-takers/me/reports', 'POST /service-takers/me/contact-logs',
  'GET /admin/dashboard', 'GET /admin/providers', 'POST /admin/providers',
  'PUT /admin/providers/:id', 'DELETE /admin/providers/:id',
  'GET /admin/categories', 'POST /admin/categories', 'PUT /admin/categories/:id',
  'DELETE /admin/categories/:id', 'GET /admin/ads', 'POST /admin/ads',
  'PATCH /admin/ads/:id', 'DELETE /admin/ads/:id', 'GET /admin/requests',
  'PATCH /admin/requests/:id/status', 'GET /admin/reports',
  'PATCH /admin/reports/:id', 'GET /admin/contact-logs',
];

const missing = flutterContracts.filter((route) => !routes.has(route));
assert.deepStrictEqual(missing, [], `Flutter API routes missing in backend: ${missing.join(', ')}`);
console.log(`Route contract passed: ${flutterContracts.length} Flutter API operations are registered.`);
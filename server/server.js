const app = require('./app');
const connectDB = require('./config/db');
const env = require('./config/env');
const ensureAdmin = require('./utils/ensureAdmin');
const ensureDefaultCategories = require('./utils/ensureDefaultCategories');

const startServer = async () => {
  await connectDB();
  await ensureDefaultCategories();

  if (process.env.SEED_ADMIN_ON_START === 'true') {
    await ensureAdmin();
  }

  const server = app.listen(env.port, () => {
    console.log('Server running on port ' + env.port);
  });
  server.requestTimeout = 30000;
  server.headersTimeout = 10000;
  server.keepAliveTimeout = 5000;
};

startServer();

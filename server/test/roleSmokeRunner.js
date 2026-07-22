const { spawn, execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const base = process.env.API_BASE_URL || 'http://127.0.0.1:5000/api';

const health = async () => {
  try {
    const response = await fetch(`${base}/health`);
    return response.ok;
  } catch (_) {
    return false;
  }
};

const waitForHealth = async (timeoutMs = 60000) => {
  const end = Date.now() + timeoutMs;
  while (Date.now() < end) {
    if (await health()) return true;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return false;
};

(async () => {
  let server;
  let ownsServer = false;
  if (!(await health())) {
    ownsServer = true;
    server = spawn(process.execPath, ['server.js'], { stdio: 'pipe', env: process.env });
    server.stdout.on('data', (chunk) => process.stdout.write(chunk));
    server.stderr.on('data', (chunk) => process.stderr.write(chunk));
    if (!(await waitForHealth())) {
      server.kill();
      throw new Error('API did not start. Check MongoDB and server configuration, then retry.');
    }
  }
  try {
    await execFileAsync(process.execPath, ['test/roleSmoke.js'], { cwd: process.cwd(), env: process.env, maxBuffer: 1024 * 1024 });
    process.stdout.write('Role smoke runner completed.\n');
  } finally {
    if (ownsServer && server && !server.killed) server.kill();
  }
})().catch((error) => {
  console.error(`Role smoke runner failed: ${error.message}`);
  process.exitCode = 1;
});
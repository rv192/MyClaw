const http = require('http');

const options = {
  hostname: 'localhost',
  port: 18789,
  path: '/health',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    console.log('✅ OpenClaw health check passed');
    process.exit(0);
  } else {
    console.log(`❌ OpenClaw health check failed: ${res.statusCode}`);
    process.exit(1);
  }
});

req.on('error', (err) => {
  console.log(`❌ OpenClaw health check error: ${err.message}`);
  process.exit(1);
});

req.on('timeout', () => {
  console.log('❌ OpenClaw health check timeout');
  req.destroy();
  process.exit(1);
});

req.end();
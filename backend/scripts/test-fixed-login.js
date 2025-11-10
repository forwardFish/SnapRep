const http = require('http');

async function testLogin() {
  console.log('🔐 Testing login after fix...');

  const postData = JSON.stringify({
    email: 'admin@snaprep.com',
    password: 'password123'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/rest/v1/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData),
    },
    timeout: 10000
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          console.log('Status:', res.statusCode);
          console.log('Headers:', res.headers);

          if (body) {
            const parsed = JSON.parse(body);
            console.log('Response:', JSON.stringify(parsed, null, 2));
          } else {
            console.log('Empty response body');
          }

          resolve({ status: res.statusCode, data: body });
        } catch (e) {
          console.log('Raw body:', body);
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request error:', error.message);
      reject(error);
    });

    req.on('timeout', () => {
      console.error('❌ Request timeout');
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

testLogin().catch(console.error);
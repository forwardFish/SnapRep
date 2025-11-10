const https = require('https');

function makeRequest(url, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: url.replace('http://localhost:3000', ''),
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
      timeout: 10000
    };

    const req = require('http').request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('Request timeout')));

    req.write(postData);
    req.end();
  });
}

async function quickLoginTest() {
  try {
    console.log('🔐 Quick login test...');

    const result = await makeRequest('http://localhost:3000/rest/v1/auth/login', {
      email: 'admin@snaprep.com',
      password: 'password123'
    });

    console.log('Status:', result.status);
    console.log('Response:', JSON.stringify(result.data, null, 2));

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

quickLoginTest();
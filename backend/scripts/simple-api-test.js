#!/usr/bin/env node

/**
 * Simple API test to trigger server logs
 */

const http = require('http');

async function testAPI() {
  console.log('🔍 Testing quick recommendation API...\n');

  const payload = {
    intent: 'STRETCH',
    equipment: ['hands_free'],
    duration: 60
  };

  console.log('Request payload:', JSON.stringify(payload, null, 2));
  console.log('\nSending request to http://localhost:3000/api/v1/recommendations/quick...\n');

  try {
    const result = await makeRequest(payload);

    console.log(`Status: ${result.statusCode}`);
    console.log(`Response Time: ${result.responseTime}ms`);
    console.log(`Response Body: ${result.body}`);

    if (result.statusCode === 200) {
      console.log('\n✅ API call successful!');
    } else {
      console.log('\n❌ API call failed!');
      console.log('Check server logs for detailed error information.');
    }

  } catch (error) {
    console.log(`\n❌ Request failed: ${error.message}`);
  }
}

function makeRequest(payload) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const postData = JSON.stringify(payload);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/v1/recommendations/quick',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
      timeout: 10000
    };

    const req = http.request(options, (res) => {
      let body = '';

      res.on('data', chunk => {
        body += chunk;
      });

      res.on('end', () => {
        const responseTime = Date.now() - startTime;
        resolve({
          statusCode: res.statusCode,
          body: body,
          responseTime: responseTime
        });
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('Request timeout')));
    req.setTimeout(10000);

    req.write(postData);
    req.end();
  });
}

if (require.main === module) {
  testAPI();
}
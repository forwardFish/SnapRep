#!/usr/bin/env node

/**
 * Test working endpoint to see server logs
 */

const http = require('http');

async function testWorkingEndpoint() {
  console.log('🔍 Testing WORKING scenario recommendation API to verify logging...\n');

  const payload = {
    scenario: 'office',
    intent: 'STRETCH'
  };

  console.log('Request payload:', JSON.stringify(payload, null, 2));
  console.log('\nSending request to http://localhost:3000/api/v1/recommendations/scenario...\n');

  try {
    const result = await makeRequest('/api/v1/recommendations/scenario', payload);

    console.log(`Status: ${result.statusCode}`);
    console.log(`Response Time: ${result.responseTime}ms`);
    console.log(`Response Body: ${result.body.substring(0, 200)}...`);

    if (result.statusCode === 200) {
      console.log('\n✅ Working API confirmed - server should show logs');
    } else {
      console.log('\n❌ Even working API failed!');
    }

  } catch (error) {
    console.log(`\n❌ Request failed: ${error.message}`);
  }

  console.log('\n' + '='.repeat(50));
  console.log('Now testing FAILING quick recommendation API...\n');

  const quickPayload = {
    intent: 'STRETCH',
    equipment: ['hands_free'],
    duration: 60
  };

  console.log('Request payload:', JSON.stringify(quickPayload, null, 2));
  console.log('\nSending request to http://localhost:3000/api/v1/recommendations/quick...\n');

  try {
    const result = await makeRequest('/api/v1/recommendations/quick', quickPayload);

    console.log(`Status: ${result.statusCode}`);
    console.log(`Response Time: ${result.responseTime}ms`);
    console.log(`Response Body: ${result.body}`);

    console.log('\n❌ Quick API still failing - check server logs for error details');

  } catch (error) {
    console.log(`\n❌ Request failed: ${error.message}`);
  }
}

function makeRequest(path, payload) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const postData = JSON.stringify(payload);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
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
  testWorkingEndpoint();
}
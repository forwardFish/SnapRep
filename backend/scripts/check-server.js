#!/usr/bin/env node

/**
 * Check what endpoints are actually available
 */

const http = require('http');

async function checkServerHealth() {
  console.log('🔍 Checking server health and available endpoints...\n');

  // Test basic connectivity
  console.log('1. Testing basic connectivity...');
  try {
    const result = await makeGetRequest('/');
    console.log(`   ✅ Root endpoint: HTTP ${result.statusCode} (${result.responseTime}ms)`);
    if (result.body) {
      console.log(`   Response: ${result.body.substring(0, 100)}`);
    }
  } catch (error) {
    console.log(`   ❌ Root endpoint failed: ${error.message}`);
    return;
  }

  // Test API base
  console.log('\n2. Testing API base...');
  try {
    const result = await makeGetRequest('/api');
    console.log(`   API base: HTTP ${result.statusCode} (${result.responseTime}ms)`);
  } catch (error) {
    console.log(`   ❌ API base failed: ${error.message}`);
  }

  // Test GraphQL
  console.log('\n3. Testing GraphQL endpoint...');
  try {
    const result = await makeGetRequest('/graphql');
    console.log(`   GraphQL: HTTP ${result.statusCode} (${result.responseTime}ms)`);
  } catch (error) {
    console.log(`   ❌ GraphQL failed: ${error.message}`);
  }

  // Test specific recommendation endpoints with GET
  console.log('\n4. Testing recommendation endpoints (GET)...');
  const endpoints = [
    '/api/v1/recommendations',
    '/api/v1/recommendations/quick',
    '/api/v1/recommendations/scenario',
    '/api/v1/recommendations/alternatives'
  ];

  for (const endpoint of endpoints) {
    try {
      const result = await makeGetRequest(endpoint);
      console.log(`   ${endpoint}: HTTP ${result.statusCode} (${result.responseTime}ms)`);
    } catch (error) {
      console.log(`   ${endpoint}: ERROR - ${error.message}`);
    }
  }

  console.log('\n5. Testing one POST to quick recommendation...');
  try {
    const payload = { intent: 'STRETCH' };
    const result = await makePostRequest('/api/v1/recommendations/quick', payload);
    console.log(`   POST quick: HTTP ${result.statusCode} (${result.responseTime}ms)`);
    console.log(`   Response: ${result.body}`);
  } catch (error) {
    console.log(`   POST quick: ERROR - ${error.message}`);
  }
}

function makeGetRequest(path) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: 'GET',
      timeout: 5000
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
    req.setTimeout(5000);
    req.end();
  });
}

function makePostRequest(path, payload) {
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
      timeout: 5000
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
    req.setTimeout(5000);

    req.write(postData);
    req.end();
  });
}

if (require.main === module) {
  checkServerHealth();
}
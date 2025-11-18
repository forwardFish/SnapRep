#!/usr/bin/env node

/**
 * 简单测试脚本 - 验证关键API修复
 *
 * 测试修复的问题：
 * 1. ✅ intentType 字段映射修复
 * 2. ✅ Supabase查询格式修复
 * 3. ✅ 支持 intents 数组参数
 */

const http = require('http');

function makeRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: responseData
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(data);
    }

    req.end();
  });
}

async function testQuickRecommendation() {
  console.log('🧪 Testing Quick Recommendation API...');

  const requestData = JSON.stringify({
    userId: 'anonymous-user',
    intents: ['RELAX'], // 修复：使用 intents 数组
    scenario: null,
    equipment: [],
    targetMuscles: ['FULL_BODY'], // 修复：只使用单个有效的enum值
    currentStep: 3
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/v1/recommendations/quick',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(requestData)
    }
  };

  try {
    console.log('📤 Sending request:', requestData);
    const response = await makeRequest(options, requestData);

    console.log(`📊 Status: ${response.statusCode}`);

    if (response.statusCode === 200) {
      console.log('✅ Quick Recommendation API - SUCCESS');
      const result = JSON.parse(response.body);
      console.log(`📋 Returned ${result.exercises?.length || 0} exercises`);
    } else {
      console.log('❌ Quick Recommendation API - FAILED');
      console.log('📝 Response:', response.body);
    }
  } catch (error) {
    console.log('❌ Quick Recommendation API - ERROR');
    console.log('💥 Error:', error.message);
  }
}

async function testEquipmentList() {
  console.log('\n🧪 Testing Equipment List API...');

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/rest/v1/equipment?page=1&pageSize=5',
    method: 'GET',
  };

  try {
    const response = await makeRequest(options);

    console.log(`📊 Status: ${response.statusCode}`);

    if (response.statusCode === 200) {
      console.log('✅ Equipment List API - SUCCESS');
      const result = JSON.parse(response.body);
      console.log(`📋 Returned ${result.data?.length || 0} equipment items`);
    } else {
      console.log('❌ Equipment List API - FAILED');
      console.log('📝 Response:', response.body);
    }
  } catch (error) {
    console.log('❌ Equipment List API - ERROR');
    console.log('💥 Error:', error.message);
  }
}

async function testScenariosList() {
  console.log('\n🧪 Testing Scenarios List API...');

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/rest/v1/scenarios',
    method: 'GET',
  };

  try {
    const response = await makeRequest(options);

    console.log(`📊 Status: ${response.statusCode}`);

    if (response.statusCode === 200) {
      console.log('✅ Scenarios List API - SUCCESS');
      const result = JSON.parse(response.body);
      console.log(`📋 Returned ${Array.isArray(result) ? result.length : 'unknown'} scenarios`);
    } else {
      console.log('❌ Scenarios List API - FAILED');
      console.log('📝 Response:', response.body);
    }
  } catch (error) {
    console.log('❌ Scenarios List API - ERROR');
    console.log('💥 Error:', error.message);
  }
}

async function runTests() {
  console.log('🚀 Running Simple API Tests\n');
  console.log('Testing fixes:');
  console.log('✅ intentType → intent_type field mapping');
  console.log('✅ Supabase query format for enum values');
  console.log('✅ Support for intents array parameter\n');

  await testQuickRecommendation();
  await testEquipmentList();
  await testScenariosList();

  console.log('\n🏁 Test Complete!');
  console.log('Check above for ✅ SUCCESS or ❌ FAILED status for each API');
}

// 检查是否作为主模块运行
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { testQuickRecommendation, testEquipmentList, testScenariosList };
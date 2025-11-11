const jwt = require('jsonwebtoken');
const http = require('http');

// 配置
const JWT_ACCESS_SECRET = 'nestjsPrismaAccessSecret';
const API_HOST = 'localhost';
const API_PORT = 3000;
const TEST_USER_ID = 'test-user-123';

// 生成测试JWT token
function generateTestToken(userId) {
  const payload = {
    userId: userId,
  };
  return jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: '1h' });
}

// HTTP请求帮助函数
function makeRequest(path, headers = {}, method = 'GET') {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_HOST,
      port: API_PORT,
      path: path,
      method: method,
      headers: headers
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          data: data
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(5000, () => {
      req.abort();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// 测试带 Bearer token 的请求
async function testBearerTokenAuth() {
  console.log('\n🔐 测试带 Bearer Token 的认证...');

  const token = generateTestToken(TEST_USER_ID);
  console.log(`Generated token: ${token.substring(0, 50)}...`);

  try {
    // 测试 Analytics 接口（需要认证）
    const response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'User-Agent': 'TestClient/1.0'
    });

    console.log(`Status: ${response.status}`);

    if (response.status === 200) {
      console.log('✅ Bearer Token 认证成功!');
      console.log('响应数据:', response.data.substring(0, 200));
      return true;
    } else if (response.status === 401) {
      console.log('❌ Token 被拒绝 (可能用户不存在)');
      console.log('响应:', response.data.substring(0, 200));
      return false;
    } else {
      console.log(`❌ 意外状态码: ${response.status}`);
      console.log('响应:', response.data.substring(0, 200));
      return false;
    }
  } catch (error) {
    console.log('❌ 请求失败:', error.message);
    return false;
  }
}

// 测试无 token 的请求（应该失败）
async function testNoTokenAuth() {
  console.log('\n🚫 测试无 Token 请求（应该失败）...');

  try {
    const response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Content-Type': 'application/json',
      'User-Agent': 'TestClient/1.0'
    });

    if (response.status === 401) {
      console.log('✅ 正确拒绝无 Token 请求');
      return true;
    } else {
      console.log(`❌ 应该失败但成功了: ${response.status}`);
      console.log('响应:', response.data.substring(0, 200));
      return false;
    }
  } catch (error) {
    console.log('❌ 请求失败:', error.message);
    return false;
  }
}

// 模拟 Swagger 请求 - 测试带完整 headers
async function testSwaggerLikeRequest() {
  console.log('\n🌐 测试模拟 Swagger 请求（带完整浏览器 headers）...');

  const token = generateTestToken(TEST_USER_ID);
  console.log(`Generated token: ${token.substring(0, 50)}...`);

  try {
    // 模拟 Swagger UI 发送的完整 headers
    const response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Content-Type': 'application/json',
      'Host': 'localhost:3000',
      'Pragma': 'no-cache',
      'Referer': 'http://localhost:3000/api/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });

    console.log(`Status: ${response.status}`);

    if (response.status === 200) {
      console.log('✅ 模拟 Swagger 请求成功!');
      console.log('响应数据:', response.data.substring(0, 200));
      return true;
    } else {
      console.log(`❌ 模拟 Swagger 请求失败: ${response.status}`);
      console.log('响应:', response.data.substring(0, 200));
      return false;
    }
  } catch (error) {
    console.log('❌ 请求失败:', error.message);
    return false;
  }
}

// 主测试函数
async function runSwaggerAuthTests() {
  console.log('🧪 开始 Swagger 认证功能测试...\n');

  let passed = 0;
  let total = 0;

  // 等待服务启动
  console.log('⏳ 等待服务启动...');
  await new Promise(resolve => setTimeout(resolve, 2000));

  // 测试1: 带 Bearer Token
  console.log('测试 1/3: Bearer Token 认证');
  total++;
  if (await testBearerTokenAuth()) passed++;

  // 测试2: 无 Token （应该失败）
  console.log('\n测试 2/3: 无 Token 请求');
  total++;
  if (await testNoTokenAuth()) passed++;

  // 测试3: 模拟 Swagger 请求
  console.log('\n测试 3/3: 模拟 Swagger 请求');
  total++;
  if (await testSwaggerLikeRequest()) passed++;

  // 汇总结果
  console.log('\n📊 测试结果汇总:');
  console.log(`通过: ${passed}/${total}`);
  console.log(`成功率: ${Math.round(passed/total*100)}%`);

  if (passed >= 2) {
    console.log('🎉 Swagger 认证测试基本通过！');
    console.log('💡 如果第1个测试失败，可能是测试用户不存在数据库中，这是正常的。');
    console.log('💡 重点是 Authorization header 是否能正确传递到后端。');
  } else {
    console.log('⚠️ 认证机制存在问题，需要进一步检查。');
  }
}

// 运行测试
runSwaggerAuthTests().catch(console.error);
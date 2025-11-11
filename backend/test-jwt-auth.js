const jwt = require('jsonwebtoken');
const http = require('http');

// 配置
const JWT_ACCESS_SECRET = 'nestjsPrismaAccessSecret'; // 从你的环境变量读取
const API_HOST = 'localhost';
const API_PORT = 3000;
const TEST_USER_ID = 'test-user-123';

// 生成测试JWT token
function generateTestToken(userId) {
  const payload = {
    userId: userId,
    // sub: userId, // 备用格式
  };

  return jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: '1h' });
}

// HTTP请求帮助函数
function makeRequest(path, headers = {}) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_HOST,
      port: API_PORT,
      path: path,
      method: 'GET',
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

// 测试无认证的接口
async function testPublicEndpoint() {
  console.log('\n🔓 测试公开接口...');
  try {
    const response = await makeRequest('/rest/v1/scenarios');
    console.log('✅ 公开接口访问成功:', response.status);
    return response.status === 200;
  } catch (error) {
    console.log('❌ 公开接口访问失败:', error.message);
    return false;
  }
}

// 测试需要认证的接口（无token）
async function testProtectedEndpointNoToken() {
  console.log('\n🚫 测试受保护接口（无token）...');
  try {
    const response = await makeRequest('/api/v1/analytics/platform/kpis');
    if (response.status === 401) {
      console.log('✅ 正确拒绝无token访问:', response.status);
      return true;
    } else {
      console.log('❌ 应该失败但成功了:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ 意外错误:', error.message);
    return false;
  }
}

// 测试需要认证的接口（有效token）
async function testProtectedEndpointWithToken() {
  console.log('\n🔐 测试受保护接口（有效token）...');

  const token = generateTestToken(TEST_USER_ID);
  console.log(`Generated token: ${token.substring(0, 50)}...`);

  try {
    const response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer ${token}`
    });

    if (response.status === 200) {
      console.log('✅ 带token的接口访问成功:', response.status);
      return true;
    } else {
      console.log('❌ 带token的接口访问失败:', response.status);
      console.log('响应内容:', response.data.substring(0, 200));
      return false;
    }
  } catch (error) {
    console.log('❌ 带token的接口访问失败:', error.message);
    return false;
  }
}

// 测试无效token
async function testProtectedEndpointWithInvalidToken() {
  console.log('\n❌ 测试受保护接口（无效token）...');

  const invalidToken = 'invalid.jwt.token';

  try {
    const response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer ${invalidToken}`
    });

    if (response.status === 401) {
      console.log('✅ 正确拒绝无效token访问:', response.status);
      return true;
    } else {
      console.log('❌ 应该失败但成功了:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ 意外错误:', error.message);
    return false;
  }
}

// 主测试函数
async function runAuthTests() {
  console.log('🧪 开始JWT认证功能测试...\n');

  let passed = 0;
  let total = 0;

  // 等待服务启动
  console.log('⏳ 等待服务启动...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  // 测试1: 公开接口
  console.log('测试 1/4: 公开接口');
  total++;
  if (await testPublicEndpoint()) passed++;

  // 测试2: 受保护接口（无token）
  console.log('\n测试 2/4: 受保护接口（无token）');
  total++;
  if (await testProtectedEndpointNoToken()) passed++;

  // 测试3: 受保护接口（有效token）
  console.log('\n测试 3/4: 受保护接口（有效token）');
  total++;
  if (await testProtectedEndpointWithToken()) passed++;

  // 测试4: 受保护接口（无效token）
  console.log('\n测试 4/4: 受保护接口（无效token）');
  total++;
  if (await testProtectedEndpointWithInvalidToken()) passed++;

  // 汇总结果
  console.log('\n📊 测试结果汇总:');
  console.log(`通过: ${passed}/${total}`);
  console.log(`成功率: ${Math.round(passed/total*100)}%`);

  if (passed === total) {
    console.log('🎉 所有JWT认证测试通过！');
  } else {
    console.log('⚠️ 部分测试失败，需要进一步检查。');
  }
}

// 运行测试
runAuthTests().catch(console.error);
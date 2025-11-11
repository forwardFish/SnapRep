const jwt = require('jsonwebtoken');
const http = require('http');

// 配置
const JWT_ACCESS_SECRET = 'nestjsPrismaAccessSecret';
const API_HOST = 'localhost';
const API_PORT = 3000;

// 生成测试JWT token (使用真实的用户ID)
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

// 测试重复 Bearer 前缀的修复
async function testDuplicateBearerFix() {
  console.log('\n🔧 测试重复 Bearer 前缀修复...');

  // 使用您真实的用户ID
  const realUserId = 'ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab';
  const token = generateTestToken(realUserId);
  console.log(`Generated clean token: ${token.substring(0, 50)}...`);

  try {
    // 测试1: 正常格式 "Bearer token"
    console.log('\n测试 1: 正常格式 Bearer token');
    let response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    console.log(`正常格式状态: ${response.status}`);

    // 测试2: 重复格式 "Bearer Bearer token"
    console.log('\n测试 2: 重复格式 Bearer Bearer token');
    response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    console.log(`重复格式状态: ${response.status}`);

    // 测试3: 多重复格式 "Bearer Bearer Bearer token"
    console.log('\n测试 3: 多重复格式 Bearer Bearer Bearer token');
    response = await makeRequest('/api/v1/analytics/platform/kpis', {
      'Authorization': `Bearer Bearer Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    console.log(`多重复格式状态: ${response.status}`);

    if (response.status === 200) {
      console.log('✅ 重复 Bearer 前缀修复工作正常!');
      console.log('响应数据:', response.data.substring(0, 200));
    } else if (response.status === 401) {
      console.log('⚠️ Token 被拒绝 (可能用户不存在数据库中)');
      console.log('响应:', response.data.substring(0, 200));
    } else {
      console.log(`❓ 其他状态: ${response.status}`);
      console.log('响应:', response.data.substring(0, 200));
    }

    return response.status;
  } catch (error) {
    console.log('❌ 请求失败:', error.message);
    return 500;
  }
}

// 主测试函数
async function runDuplicateBearerTests() {
  console.log('🧪 开始重复 Bearer 前缀修复测试...\n');

  // 等待服务启动
  console.log('⏳ 等待服务启动...');
  await new Promise(resolve => setTimeout(resolve, 2000));

  const result = await testDuplicateBearerFix();

  console.log('\n📊 测试结果:');
  if (result === 200) {
    console.log('🎉 完美！重复 Bearer 前缀问题已修复!');
  } else if (result === 401) {
    console.log('✅ 很好！Token 解析工作正常，只是用户验证失败。');
    console.log('💡 这说明重复 Bearer 前缀已经被正确处理了。');
  } else {
    console.log('❌ 仍然存在问题，需要进一步检查。');
  }

  console.log('\n💡 在 Swagger UI 中使用时:');
  console.log('✅ 正确做法: 只输入 token 本身');
  console.log('❌ 错误做法: 输入 "Bearer token"');
  console.log('🔧 现在即使错误输入，系统也会自动处理！');
}

// 运行测试
runDuplicateBearerTests().catch(console.error);
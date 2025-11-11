const fetch = require('node-fetch');
const jwt = require('jsonwebtoken');

/**
 * 完整的JWT认证调试脚本
 * 测试从登录到API访问的完整流程，并提供详细日志
 */
async function runAuthenticationDebugTest() {
  console.log('🚀 开始完整的JWT认证调试测试');
  console.log('================================\n');

  try {
    // Step 1: 测试登录并获取JWT token
    console.log('🔐 Step 1: 用户登录测试');
    console.log('--------------------');

    const loginResponse = await fetch('http://localhost:3000/rest/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'admin@snaprep.com', // 使用日志中显示成功登录的邮箱
        password: 'Admin123456!'
      })
    });

    console.log(`📊 Login Response Status: ${loginResponse.status} ${loginResponse.statusText}`);

    const loginText = await loginResponse.text();
    console.log(`📝 Login Response Body: ${loginText}\n`);

    if (loginResponse.status !== 200) {
      console.error('❌ 登录失败，无法继续测试');
      return;
    }

    const loginData = JSON.parse(loginText);
    const accessToken = loginData.data?.accessToken;

    if (!accessToken) {
      console.error('❌ 登录响应中没有找到 accessToken');
      return;
    }

    console.log(`✅ 登录成功，获得 access token`);
    console.log(`🎫 Token 长度: ${accessToken.length} 字符\n`);

    // Step 2: 解析JWT token
    console.log('🔍 Step 2: JWT Token 解析');
    console.log('-------------------------');

    try {
      // 解码 header
      const [headerB64, payloadB64, signature] = accessToken.split('.');

      const header = JSON.parse(Buffer.from(headerB64, 'base64').toString());
      console.log(`📋 Token Header: ${JSON.stringify(header, null, 2)}`);

      const payload = JSON.parse(Buffer.from(payloadB64, 'base64').toString());
      console.log(`📋 Token Payload: ${JSON.stringify(payload, null, 2)}`);

      const now = Math.floor(Date.now() / 1000);
      const isExpired = payload.exp < now;

      console.log(`⏰ Current Time: ${now} (${new Date().toISOString()})`);
      console.log(`⏰ Token Expires: ${payload.exp} (${new Date(payload.exp * 1000).toISOString()})`);
      console.log(`✅ Token Valid: ${!isExpired}\n`);

      if (isExpired) {
        console.error('❌ Token已过期，无法继续测试');
        return;
      }

    } catch (decodeError) {
      console.error(`❌ Token解析失败: ${decodeError.message}`);
      return;
    }

    // Step 3: 验证JWT签名
    console.log('🔐 Step 3: JWT 签名验证');
    console.log('---------------------');

    try {
      const jwtSecret = 'nestjsPrismaAccessSecret'; // 从.env读取的JWT_ACCESS_SECRET
      const decoded = jwt.verify(accessToken, jwtSecret);
      console.log(`✅ JWT签名验证成功`);
      console.log(`👤 Decoded Payload: ${JSON.stringify(decoded, null, 2)}\n`);
    } catch (verifyError) {
      console.error(`❌ JWT签名验证失败: ${verifyError.message}`);
      console.error(`🔍 这可能是JWT_ACCESS_SECRET配置错误\n`);
      // 继续测试以获取更多信息
    }

    // Step 4: 测试受保护的API端点
    console.log('🛡️ Step 4: 受保护API访问测试');
    console.log('-----------------------------');

    const protectedUrls = [
      '/api/v1/cards/public?limit=1&offset=3', // 原始错误URL
      '/api/v1/analytics/users/ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab/funnel',
      '/rest/v1/auth/me' // 简单的用户信息端点
    ];

    for (const url of protectedUrls) {
      console.log(`🎯 测试端点: ${url}`);

      const apiResponse = await fetch(`http://localhost:3000${url}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`📊 Response Status: ${apiResponse.status} ${apiResponse.statusText}`);

      const apiResponseText = await apiResponse.text();
      console.log(`📝 Response Body: ${apiResponseText.substring(0, 500)}${apiResponseText.length > 500 ? '...' : ''}`);

      if (apiResponse.status === 200) {
        console.log(`✅ 端点访问成功！`);
      } else if (apiResponse.status === 401) {
        console.log(`❌ 401 Unauthorized - JWT验证失败`);
      } else {
        console.log(`⚠️ 其他错误: ${apiResponse.status}`);
      }
      console.log('---');
    }

    // Step 5: 手动构造JWT进行测试
    console.log('\n🔧 Step 5: 手动JWT构造测试');
    console.log('---------------------------');

    try {
      const jwtSecret = 'nestjsPrismaAccessSecret';
      const testPayload = {
        userId: 'ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab', // 从原始报错中的userId
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600 // 1小时后过期
      };

      const testToken = jwt.sign(testPayload, jwtSecret);
      console.log(`🎫 手动构造的Token: ${testToken.substring(0, 50)}...`);

      const testApiResponse = await fetch('http://localhost:3000/rest/v1/auth/me', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${testToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`📊 测试Token Status: ${testApiResponse.status} ${testApiResponse.statusText}`);

      const testApiText = await testApiResponse.text();
      console.log(`📝 测试Token Response: ${testApiText.substring(0, 300)}${testApiText.length > 300 ? '...' : ''}\n`);

    } catch (manualTestError) {
      console.error(`❌ 手动JWT测试失败: ${manualTestError.message}\n`);
    }

  } catch (error) {
    console.error(`💥 测试脚本执行失败: ${error.message}`);
    console.error(`📊 Error stack: ${error.stack}`);
  }

  console.log('🏁 认证调试测试完成');
  console.log('==================');
}

// 运行测试
runAuthenticationDebugTest();
const axios = require('axios');

async function testWithAuth() {
  try {
    // 1. 先登录获取token
    console.log('🔐 正在获取认证token...');
    const loginResponse = await axios.post('http://localhost:3000/rest/v1/auth/login', {
      email: 'admin@snaprep.com',
      password: 'Linlin@123'
    });

    const token = loginResponse.data?.data?.access_token || loginResponse.data?.access_token;

    if (!token) {
      console.log('❌ 登录失败，无法获取token');
      console.log('Response:', loginResponse.data);
      return;
    }

    console.log('✅ 成功获取token:', token.substring(0, 50) + '...');

    // 2. 使用token测试workout-sessions健康检查
    console.log('\n🔍 测试 Workout Sessions Health (带认证)');
    const healthResponse = await axios.get('http://localhost:3000/api/v1/workout-sessions/health', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('✅ Workout Sessions Health 响应:');
    console.log('Status:', healthResponse.status);
    console.log('Data:', healthResponse.data);

    // 3. 测试创建workout session (也需要认证)
    console.log('\n🔍 测试 Create Workout Session (带认证)');
    const createSessionResponse = await axios.post('http://localhost:3000/api/v1/workout-sessions', {
      userId: 'test-user',
      intentType: 'RELAX',
      difficulty: 'GREEN',
      exercises: []
    }, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('✅ Create Workout Session 响应:');
    console.log('Status:', createSessionResponse.status);
    console.log('Data:', createSessionResponse.data);

  } catch (error) {
    console.log('❌ 错误:', error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Response data:', error.response.data);
    }
  }
}

testWithAuth();
const fetch = require('node-fetch');

async function testLogin() {
  try {
    console.log('🔐 Testing login with updated password hash...');

    const response = await fetch('http://localhost:3000/rest/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'admin@snaprep.com',
        password: 'password123'
      }),
    });

    const result = await response.json();

    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(result, null, 2));

    if (response.ok) {
      console.log('✅ 登录成功！');
      return true;
    } else {
      console.log('❌ 登录失败！');
      return false;
    }
  } catch (error) {
    console.error('❌ 登录请求失败:', error.message);
    return false;
  }
}

testLogin();
/**
 * 通过 Supabase Auth API 创建测试用户
 * 这会同时在 auth.users 和 public.users 中创建用户
 */
const fetch = require('node-fetch');

async function createAuthUser() {
  try {
    console.log('🚀 Creating user through Supabase Auth API...');

    // 首先注册用户（这会在 auth.users 表中创建记录）
    const registerResponse = await fetch('http://localhost:3000/rest/v1/auth/register', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'admin@snaprep.com',
        password: 'password123',
        name: 'SnapRep管理员'
      }),
    });

    const registerResult = await registerResponse.json();

    console.log('Registration Status:', registerResponse.status);
    console.log('Registration Response:', JSON.stringify(registerResult, null, 2));

    if (registerResponse.ok) {
      console.log('✅ 用户注册成功！现在可以登录了');

      // 测试登录
      console.log('\n🔐 Testing login...');

      const loginResponse = await fetch('http://localhost:3000/rest/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: 'admin@snaprep.com',
          password: 'password123'
        }),
      });

      const loginResult = await loginResponse.json();

      console.log('Login Status:', loginResponse.status);
      console.log('Login Response:', JSON.stringify(loginResult, null, 2));

      if (loginResponse.ok) {
        console.log('🎉 登录测试成功！');
      } else {
        console.log('❌ 登录仍然失败');
      }
    } else {
      console.log('❌ 用户注册失败');

      // 检查是否是用户已存在的错误
      if (registerResult.message && registerResult.message.includes('already')) {
        console.log('👤 用户可能已存在，直接测试登录...');

        const loginResponse = await fetch('http://localhost:3000/rest/v1/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            email: 'admin@snaprep.com',
            password: 'password123'
          }),
        });

        const loginResult = await loginResponse.json();
        console.log('Login Status:', loginResponse.status);
        console.log('Login Response:', JSON.stringify(loginResult, null, 2));
      }
    }
  } catch (error) {
    console.error('❌ 请求失败:', error.message);
  }
}

createAuthUser();
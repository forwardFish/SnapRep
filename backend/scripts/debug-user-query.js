/**
 * 调试 getUserFromDatabase 为什么返回 null
 */

// 检查环境变量
console.log('🔧 Environment variables:');
console.log('SUPABASE_URL:', process.env.SUPABASE_URL || 'undefined');
console.log('SUPABASE_ANON_KEY:', process.env.SUPABASE_ANON_KEY ? 'exists' : 'undefined');
console.log('SUPABASE_SERVICE_KEY:', process.env.SUPABASE_SERVICE_KEY ? 'exists' : 'undefined');

// 模拟 SupabaseApiService 的 getById 逻辑
async function testSupabaseQuery() {
  const fetch = require('node-fetch');

  const SUPABASE_URL = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
  const ANON_KEY = process.env.SUPABASE_ANON_KEY || 'YOUR_ANON_KEY';
  const USER_ID = 'ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab';

  console.log('\n🔍 Testing direct Supabase REST API query...');
  console.log('Target User ID:', USER_ID);

  const searchParams = new URLSearchParams();
  searchParams.append('id', `eq.${USER_ID}`);
  searchParams.append('limit', '1');

  const url = `${SUPABASE_URL}/rest/v1/users?${searchParams}`;

  console.log('Request URL:', url);
  console.log('Headers:', {
    'apikey': ANON_KEY.substring(0, 20) + '...',
    'Authorization': `Bearer ${ANON_KEY.substring(0, 20)}...`,
    'Content-Type': 'application/json',
  });

  try {
    const response = await fetch(url, {
      headers: {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    console.log('\n📊 Response status:', response.status, response.statusText);

    if (!response.ok) {
      const errorText = await response.text();
      console.log('❌ Error response body:', errorText);
      return;
    }

    const data = await response.json();
    console.log('✅ Response data:', JSON.stringify(data, null, 2));
    console.log('📈 Records found:', data.length);

    if (data.length === 0) {
      console.log('\n🔍 No records found. Let\'s test with a basic query...');

      // 测试获取所有用户
      const allUsersUrl = `${SUPABASE_URL}/rest/v1/users?limit=5`;
      console.log('Testing URL:', allUsersUrl);

      const allUsersResponse = await fetch(allUsersUrl, {
        headers: {
          'apikey': ANON_KEY,
          'Authorization': `Bearer ${ANON_KEY}`,
          'Content-Type': 'application/json',
        },
      });

      if (allUsersResponse.ok) {
        const allUsers = await allUsersResponse.json();
        console.log('📋 All users (first 5):');
        allUsers.forEach((user, index) => {
          console.log(`  ${index + 1}. ID: ${user.id}, Email: ${user.email}`);
        });
      } else {
        console.log('❌ Failed to fetch all users:', allUsersResponse.status);
      }
    }
  } catch (error) {
    console.error('❌ Request failed:', error.message);
  }
}

// 运行测试
testSupabaseQuery();
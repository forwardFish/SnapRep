/**
 * 通过 Supabase Auth API 创建测试用户
 * 这样密码会被正确加密存储
 */
const { createClient } = require('@supabase/supabase-js');

async function createTestUsers() {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // 需要服务端密钥

  if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    return;
  }

  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: { autoRefreshToken: false, persistSession: false }
  });

  const testUsers = [
    { email: 'admin@snaprep.com', password: 'password123', name: 'SnapRep管理员' },
    { email: 'test@snaprep.com', password: 'password123', name: '测试用户' },
    { email: 'alice@example.com', password: 'password123', name: 'Alice' },
    { email: 'bob@example.com', password: 'password123', name: 'Bob' },
    { email: 'charlie@example.com', password: 'password123', name: 'Charlie' },
  ];

  for (const userData of testUsers) {
    try {
      console.log(`创建用户: ${userData.email}`);

      // 通过 Supabase Auth 创建用户
      const { data, error } = await supabase.auth.admin.createUser({
        email: userData.email,
        password: userData.password,
        user_metadata: {
          name: userData.name
        },
        email_confirm: true // 自动验证邮箱
      });

      if (error) {
        console.error(`创建用户失败 ${userData.email}:`, error);
      } else {
        console.log(`✓ 创建用户成功: ${userData.email}, ID: ${data.user.id}`);
      }
    } catch (err) {
      console.error(`创建用户异常 ${userData.email}:`, err);
    }
  }

  console.log('测试用户创建完成');
}

// 如果直接运行此脚本
if (require.main === module) {
  createTestUsers().catch(console.error);
}

module.exports = { createTestUsers };
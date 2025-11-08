#!/usr/bin/env node

/**
 * 增强版 Supabase 连接配置指南
 * 提供详细的连接字符串获取和测试步骤
 */

console.log('🔧 Supabase 数据库连接配置完整指南\n');

console.log('📋 步骤 1: 获取正确的连接字符串');
console.log('=' .repeat(50));
console.log('1. 访问 Supabase 控制台:');
console.log('   🔗 https://app.supabase.com/project/tvjcmleckqovnieuexgu\n');

console.log('2. 导航到数据库设置:');
console.log('   - 左侧菜单: Settings → Database\n');

console.log('3. 找到连接字符串部分:');
console.log('   - 向下滚动找到 "Connection string" 部分\n');

console.log('4. 获取连接字符串 (推荐顺序):');
console.log('   ✅ 首选: Session mode (端口 6543)');
console.log('   ✅ 备选: Transaction mode (端口 6543)');
console.log('   ❌ 避免: Direct connection (端口 5432) - 可能被限制\n');

console.log('5. 连接字符串格式示例:');
console.log('   正确格式 (Pooler):');
console.log('   postgresql://postgres.xxx:[密码]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres');
console.log('   ');
console.log('   错误格式 (Direct - 被限制):');
console.log('   postgresql://postgres:[密码]@db.tvjcmleckqovnieuexgu.supabase.co:5432/postgres\n');

console.log('📋 步骤 2: 更新 .env 配置文件');
console.log('=' .repeat(50));
console.log('编辑 backend/.env 文件，更新以下两行:');
console.log('');
console.log('DATABASE_URL="[从 Supabase 复制的连接字符串]"');
console.log('DIRECT_URL="[相同的连接字符串]"');
console.log('');
console.log('⚠️  注意事项:');
console.log('- 确保包含正确的密码');
console.log('- 确保端口是 6543 而不是 5432');
console.log('- 确保域名包含 pooler.supabase.com');
console.log('- 连接字符串末尾添加 ?sslmode=require\n');

console.log('📋 步骤 3: 验证连接');
console.log('=' .repeat(50));
console.log('运行以下命令验证连接:');
console.log('');
console.log('1. 测试连接:');
console.log('   cd backend');
console.log('   node scripts/test-database-connection.js');
console.log('');
console.log('2. 如果连接成功，重启服务器:');
console.log('   npm run start:dev');
console.log('');
console.log('3. 测试 API:');
console.log('   npm run test:health');
console.log('');

console.log('🔍 常见问题排查');
console.log('=' .repeat(50));
console.log('如果仍然无法连接:');
console.log('');
console.log('1. 检查 Supabase 项目状态:');
console.log('   - 项目是否处于活跃状态 (未暂停)');
console.log('   - 数据库是否正在运行');
console.log('');
console.log('2. 检查连接字符串:');
console.log('   - 密码是否正确');
console.log('   - 用户名格式 (postgres vs postgres.xxx)');
console.log('   - 端口号 (应该是 6543)');
console.log('');
console.log('3. 网络问题:');
console.log('   - 尝试不同的网络环境');
console.log('   - 检查防火墙设置');
console.log('');

console.log('✅ 连接成功后的预期结果:');
console.log('=' .repeat(50));
console.log('- ✅ 数据库连接测试通过');
console.log('- ✅ API 健康检查 100% 成功');
console.log('- ✅ Quick recommendation API 正常工作');
console.log('- ✅ 所有 DAO 查询正常执行');
console.log('');
console.log('🎉 一旦连接成功，你之前遇到的所有 500 错误都将消失！');

console.log('\n' + '='.repeat(60));
console.log('下一步: 请按照上述步骤操作，然后运行测试命令验证连接');
console.log('='.repeat(60));
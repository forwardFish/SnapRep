#!/usr/bin/env node

/**
 * Supabase 数据库连接测试和修复工具
 * 帮助诊断和解决数据库连接问题
 */

const { PrismaClient } = require('@prisma/client');

async function testDatabaseConnection() {
  console.log('🔍 Supabase 数据库连接诊断...\n');

  // 显示当前配置
  console.log('📋 当前配置检查:');
  console.log(`DATABASE_URL: ${process.env.DATABASE_URL ? '已设置' : '❌ 未设置'}`);
  console.log(`DIRECT_URL: ${process.env.DIRECT_URL ? '已设置' : '❌ 未设置'}`);

  if (process.env.DATABASE_URL) {
    // 隐藏密码显示连接信息
    const maskedUrl = process.env.DATABASE_URL.replace(/:[^:@]*@/, ':***@');
    console.log(`连接字符串: ${maskedUrl}`);
  }
  console.log('');

  // 尝试各种连接方法
  const prisma = new PrismaClient();

  try {
    console.log('🔄 测试1: 基础数据库连接...');
    await prisma.$connect();
    console.log('✅ 数据库连接成功！');

    console.log('\n🔄 测试2: 检查数据库版本...');
    const result = await prisma.$queryRaw`SELECT version()`;
    console.log('✅ 数据库查询成功:', result[0].version.substring(0, 50) + '...');

    console.log('\n🔄 测试3: 检查表是否存在...');
    const tables = await prisma.$queryRaw`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      LIMIT 5
    `;
    console.log('✅ 表检查成功，找到表:', tables.map(t => t.table_name).join(', '));

    console.log('\n🔄 测试4: 测试exercises表查询...');
    const exercisesCount = await prisma.exercise.count();
    console.log(`✅ exercises表查询成功，共有 ${exercisesCount} 条记录`);

    console.log('\n🎉 所有测试通过！数据库连接完全正常。');
    console.log('   之前的错误可能是临时网络问题，现在应该可以正常工作了。');

  } catch (error) {
    console.log('❌ 数据库连接失败:\n');

    if (error.code === 'P1001') {
      console.log('🔍 错误类型: 无法连接到数据库服务器');
      console.log('🛠️  可能的解决方案:');
      console.log('');
      console.log('1. 检查 Supabase 项目状态:');
      console.log('   - 访问: https://app.supabase.com/project/tvjcmleckqovnieuexgu');
      console.log('   - 确认项目未暂停');
      console.log('   - 检查数据库是否正在运行');
      console.log('');
      console.log('2. 更新连接字符串:');
      console.log('   - Supabase 控制台 → Settings → Database');
      console.log('   - 选择 "Connection string" → "Nodejs"');
      console.log('   - 复制新的连接字符串');
      console.log('   - 更新 .env 文件中的 DATABASE_URL 和 DIRECT_URL');
      console.log('');
      console.log('3. 检查连接字符串格式:');
      console.log('   正确格式: postgresql://postgres:[YOUR-PASSWORD]@db.[REF].supabase.co:5432/postgres?sslmode=require');
      console.log('');
      console.log('4. 如果使用 Pooling 连接:');
      console.log('   - 尝试使用 Transaction mode 连接字符串');
      console.log('   - 端口可能是 5432 或 6543');
    } else {
      console.log(`❌ 其他错误 (${error.code}): ${error.message}`);
    }

    console.log('\n📋 详细错误信息:');
    console.log(error.message);
  } finally {
    await prisma.$disconnect();
  }
}

// 立即运行测试
if (require.main === module) {
  testDatabaseConnection().catch(console.error);
}
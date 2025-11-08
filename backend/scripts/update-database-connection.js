#!/usr/bin/env node

/**
 * 交互式数据库连接字符串更新工具
 * 帮助用户安全地更新 .env 配置
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function updateDatabaseConnection() {
  console.log('🔧 Supabase 数据库连接配置助手\n');

  // 检查当前配置
  const envPath = path.join(process.cwd(), '.env');

  if (!fs.existsSync(envPath)) {
    console.log('❌ 未找到 .env 文件');
    console.log('请确保你在 backend 目录下运行此脚本');
    process.exit(1);
  }

  console.log('📋 当前配置状态:');
  const envContent = fs.readFileSync(envPath, 'utf8');
  const currentDbUrl = envContent.match(/DATABASE_URL="([^"]+)"/);
  const currentDirectUrl = envContent.match(/DIRECT_URL="([^"]+)"/);

  if (currentDbUrl) {
    const maskedUrl = currentDbUrl[1].replace(/:[^:@]*@/, ':***@');
    console.log(`DATABASE_URL: ${maskedUrl}`);
  } else {
    console.log('DATABASE_URL: 未设置');
  }

  if (currentDirectUrl) {
    const maskedUrl = currentDirectUrl[1].replace(/:[^:@]*@/, ':***@');
    console.log(`DIRECT_URL: ${maskedUrl}`);
  } else {
    console.log('DIRECT_URL: 未设置');
  }

  console.log('\n🔍 检测到的问题:');
  if (currentDbUrl && currentDbUrl[1].includes(':5432')) {
    console.log('❌ 当前使用端口 5432 (直连，可能被限制)');
    console.log('✅ 建议改为端口 6543 (连接池)');
  }

  if (currentDbUrl && currentDbUrl[1].includes('db.tvjcmleckqovnieuexgu.supabase.co')) {
    console.log('❌ 当前使用直连域名');
    console.log('✅ 建议改为连接池域名 (pooler.supabase.com)');
  }

  console.log('\n' + '='.repeat(50));
  console.log('请按照以下步骤获取新的连接字符串:');
  console.log('1. 访问: https://app.supabase.com/project/tvjcmleckqovnieuexgu');
  console.log('2. Settings → Database → Connection string');
  console.log('3. 选择 "Session" 或 "Transaction" 模式');
  console.log('4. 复制完整的连接字符串');
  console.log('=' .repeat(50));

  return new Promise((resolve) => {
    rl.question('\n请粘贴新的连接字符串 (或按 Enter 跳过): ', (newConnectionString) => {
      if (!newConnectionString.trim()) {
        console.log('\n⚠️  跳过更新。请手动编辑 .env 文件。');
        console.log('参考格式:');
        console.log('DATABASE_URL="postgresql://postgres.xxx:[密码]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require"');
        console.log('DIRECT_URL="[相同的连接字符串]"');
        rl.close();
        resolve();
        return;
      }

      // 验证连接字符串格式
      if (!newConnectionString.startsWith('postgresql://')) {
        console.log('❌ 连接字符串格式不正确，应该以 postgresql:// 开头');
        rl.close();
        resolve();
        return;
      }

      // 检查是否是推荐的连接池格式
      if (newConnectionString.includes('pooler.supabase.com:6543')) {
        console.log('✅ 检测到连接池格式 (推荐)');
      } else if (newConnectionString.includes(':5432')) {
        console.log('⚠️  检测到直连格式，可能存在连接问题');
      }

      try {
        // 备份当前 .env 文件
        const backupPath = `.env.backup.${Date.now()}`;
        fs.copyFileSync(envPath, backupPath);
        console.log(`✅ 已备份当前配置到: ${backupPath}`);

        // 更新 .env 文件
        let updatedContent = envContent;

        // 更新 DATABASE_URL
        if (currentDbUrl) {
          updatedContent = updatedContent.replace(
            /DATABASE_URL="[^"]+"/,
            `DATABASE_URL="${newConnectionString}"`
          );
        } else {
          updatedContent += `\nDATABASE_URL="${newConnectionString}"`;
        }

        // 更新 DIRECT_URL
        if (currentDirectUrl) {
          updatedContent = updatedContent.replace(
            /DIRECT_URL="[^"]+"/,
            `DIRECT_URL="${newConnectionString}"`
          );
        } else {
          updatedContent += `\nDIRECT_URL="${newConnectionString}"`;
        }

        fs.writeFileSync(envPath, updatedContent);
        console.log('✅ .env 文件已更新');

        console.log('\n🎯 下一步:');
        console.log('1. 运行测试: node scripts/test-database-connection.js');
        console.log('2. 如果成功，重启服务器: npm run start:dev');
        console.log('3. 测试 API: npm run test:health');

      } catch (error) {
        console.log('❌ 更新失败:', error.message);
      }

      rl.close();
      resolve();
    });
  });
}

if (require.main === module) {
  updateDatabaseConnection().catch(console.error);
}
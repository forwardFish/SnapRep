#!/usr/bin/env node

/**
 * 独立的数据库连接检查工具
 * 使用直接SQL查询，避免Prisma ORM冲突
 */

const { Client } = require('pg');
require('dotenv').config();

async function directDatabaseCheck() {
  console.log('🔍 直接数据库检查 (绕过Prisma)...\n');

  // 解析DATABASE_URL
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.log('❌ DATABASE_URL未设置');
    return;
  }

  console.log('📋 使用连接:', databaseUrl.replace(/:[^:@]*@/, ':***@'));

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('✅ 直接数据库连接成功\n');

    // 1. 检查表是否存在
    console.log('1. 检查关键表:');
    const tables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('exercises', 'equipment', 'exercise_equipment')
      ORDER BY table_name
    `);

    const tableNames = tables.rows.map(row => row.table_name);
    console.log(`   找到表: ${tableNames.join(', ')}`);

    if (!tableNames.includes('exercises')) {
      console.log('❌ 缺少 exercises 表 - 需要运行数据库迁移');
      return;
    }

    // 2. 检查数据量
    console.log('\n2. 检查数据量:');
    for (const table of ['exercises', 'equipment', 'exercise_equipment']) {
      if (tableNames.includes(table)) {
        const result = await client.query(`SELECT COUNT(*) as count FROM ${table}`);
        console.log(`   ${table}: ${result.rows[0].count} 条记录`);
      }
    }

    // 3. 检查关键数据
    console.log('\n3. 检查关键器材:');
    const equipment = await client.query(`
      SELECT code, name FROM equipment
      WHERE code IN ('hands_free', 'none', 'chair', 'wall')
      ORDER BY code
    `);
    if (equipment.rows.length > 0) {
      equipment.rows.forEach(row => {
        console.log(`   ✅ ${row.code}: ${row.name}`);
      });
    } else {
      console.log('   ❌ 未找到基础器材数据');
    }

    // 4. 检查意图类型
    console.log('\n4. 检查动作意图类型:');
    const intents = await client.query(`
      SELECT DISTINCT "intentType" as intent, COUNT(*) as count
      FROM exercises
      GROUP BY "intentType"
      ORDER BY "intentType"
    `);
    if (intents.rows.length > 0) {
      intents.rows.forEach(row => {
        console.log(`   ${row.intent}: ${row.count} 个动作`);
      });
    } else {
      console.log('   ❌ 未找到动作数据');
    }

    // 5. 关键检查：推荐算法所需数据
    console.log('\n5. 检查推荐算法数据完整性:');
    const recommendation = await client.query(`
      SELECT
        e.code,
        e.name::text,
        e."intentType",
        eq.code as equipment_code
      FROM exercises e
      JOIN exercise_equipment ee ON e.id = ee."exerciseId"
      JOIN equipment eq ON ee."equipmentId" = eq.id
      WHERE e."intentType" = 'STRETCH'
      AND eq.code = 'hands_free'
      LIMIT 3
    `);

    if (recommendation.rows.length > 0) {
      console.log(`   ✅ 找到 ${recommendation.rows.length} 个可推荐动作:`);
      recommendation.rows.forEach(row => {
        // Handle JSON name field
        let name = row.name;
        try {
          if (name && name.startsWith('{')) {
            const nameObj = JSON.parse(name);
            name = nameObj.name || nameObj.zh || name;
          }
        } catch (e) {
          // Keep original name if JSON parsing fails
        }
        console.log(`      - ${row.code}: ${name} (${row.intenttype}, ${row.equipment_code})`);
      });

      console.log('\n🎉 数据完整！推荐API应该可以工作');
      console.log('   问题可能在于:');
      console.log('   1. 业务逻辑层的错误处理');
      console.log('   2. 参数验证失败');
      console.log('   3. 服务间依赖问题');

    } else {
      console.log('   ❌ 未找到 STRETCH + hands_free 组合数据');
      console.log('   推荐: 检查测试数据是否正确导入');
    }

  } catch (error) {
    console.log('❌ 直接数据库查询失败:', error.message);
    console.log('可能原因: 表结构不匹配或数据尚未导入');
  } finally {
    await client.end();
  }
}

if (require.main === module) {
  directDatabaseCheck().catch(console.error);
}
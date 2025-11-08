#!/usr/bin/env node

/**
 * 简单的SQL查询检查测试数据
 * 避免Prisma连接池冲突
 */

const { PrismaClient } = require('@prisma/client');

async function simpleDataCheck() {
  console.log('🔍 检查推荐API所需的基础数据...\n');

  let prisma;
  try {
    prisma = new PrismaClient();

    console.log('1. 检查exercises表:');
    const exercises = await prisma.$queryRaw`SELECT COUNT(*) as count FROM exercises`;
    console.log(`   总动作数: ${exercises[0].count}`);

    console.log('\n2. 检查equipment表:');
    const equipment = await prisma.$queryRaw`SELECT COUNT(*) as count FROM equipment`;
    console.log(`   总器材数: ${equipment[0].count}`);

    console.log('\n3. 检查关键器材 hands_free:');
    const handsFreee = await prisma.$queryRaw`SELECT * FROM equipment WHERE code = 'hands_free' LIMIT 1`;
    if (handsFreee.length > 0) {
      console.log(`   ✅ 找到: ${handsFreee[0].name} (${handsFreee[0].code})`);
    } else {
      console.log('   ❌ 未找到 hands_free 器材');
    }

    console.log('\n4. 检查 STRETCH 意图的动作:');
    const stretchExercises = await prisma.$queryRaw`SELECT COUNT(*) as count FROM exercises WHERE "intentType" = 'STRETCH'`;
    console.log(`   STRETCH动作数: ${stretchExercises[0].count}`);

    console.log('\n5. 检查所有 intentType 值:');
    const intents = await prisma.$queryRaw`SELECT DISTINCT "intentType" FROM exercises ORDER BY "intentType"`;
    console.log(`   意图类型: ${intents.map(i => i.intentType).join(', ')}`);

    console.log('\n6. 检查动作-器材关联表:');
    const relations = await prisma.$queryRaw`SELECT COUNT(*) as count FROM exercise_equipment`;
    console.log(`   动作-器材关联数: ${relations[0].count}`);

    // 关键检查：是否有可推荐的动作
    console.log('\n🎯 关键检查: STRETCH + hands_free 组合:');
    const validExercises = await prisma.$queryRaw`
      SELECT e.code, e.name, e."intentType"
      FROM exercises e
      JOIN exercise_equipment ee ON e.id = ee."exerciseId"
      JOIN equipment eq ON ee."equipmentId" = eq.id
      WHERE e."intentType" = 'STRETCH'
      AND eq.code = 'hands_free'
      LIMIT 3
    `;

    if (validExercises.length > 0) {
      console.log(`   ✅ 找到 ${validExercises.length} 个匹配动作:`);
      validExercises.forEach(ex => {
        const name = typeof ex.name === 'object' ? ex.name.name : ex.name;
        console.log(`      - ${ex.code}: ${name}`);
      });
      console.log('\n🔍 数据存在，问题可能在推荐算法逻辑中');
    } else {
      console.log('   ❌ 没有找到匹配的动作!');
      console.log('\n❌ 关键问题: 缺少 STRETCH + hands_free 的动作数据');
      console.log('   这解释了为什么推荐API返回500错误');
    }

  } catch (error) {
    console.log('❌ 检查失败:', error.message);
    console.log('\n可能的原因:');
    console.log('1. 数据库表结构与代码不匹配');
    console.log('2. 缺少基础测试数据');
    console.log('3. Prisma schema定义问题');
  } finally {
    if (prisma) {
      await prisma.$disconnect();
    }
  }
}

if (require.main === module) {
  simpleDataCheck().catch(console.error);
}
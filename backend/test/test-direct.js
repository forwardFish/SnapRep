const { PrismaClient } = require('@prisma/client');

async function testDirectConnection() {
  console.log('🔍 使用直连端口(5432)测试数据库连接...\n');

  // 使用直连URL创建Prisma客户端
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: process.env.DIRECT_URL
      }
    }
  });

  try {
    // 测试连接
    console.log('1️⃣ 测试数据库连接...');
    await prisma.$connect();
    console.log('   ✅ 直连成功！');

    // 测试查询
    console.log('\n2️⃣ 测试基本查询...');
    const scenarioCount = await prisma.scenario.count();
    console.log(`   ✅ 场景表查询成功，共 ${scenarioCount} 条记录`);

    const equipmentCount = await prisma.equipment.count();
    console.log(`   ✅ 设备表查询成功，共 ${equipmentCount} 条记录`);

    const exerciseCount = await prisma.exercise.count();
    console.log(`   ✅ 练习表查询成功，共 ${exerciseCount} 条记录`);

    // 测试数据示例
    console.log('\n3️⃣ 获取示例数据...');
    const scenarios = await prisma.scenario.findMany({
      take: 2,
      select: { code: true, name: true, isActive: true }
    });
    scenarios.forEach(s => {
      console.log(`   📍 ${s.code}: ${s.name} (${s.isActive ? '启用' : '禁用'})`);
    });

    console.log('\n🎉 直连测试全部通过！数据库工作正常。');
    console.log('⚠️  问题在于pgbouncer端口6543不可达。');

  } catch (error) {
    console.log('\n❌ 直连测试失败:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testDirectConnection().catch(console.error);
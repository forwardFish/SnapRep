// 验证修复后的连接
const { PrismaClient } = require('@prisma/client');

async function verifyFix() {
  console.log('🔍 验证修复后的数据库连接...\n');

  const prisma = new PrismaClient();

  try {
    await prisma.$connect();
    console.log('✅ 默认连接成功！');

    // 测试API会用到的查询
    const scenarios = await prisma.scenario.findMany({
      select: { id: true, code: true, name: true, isActive: true }
    });
    console.log(`✅ 场景API数据: ${scenarios.length} 个场景`);

    const equipment = await prisma.equipment.findMany({
      take: 3,
      select: { code: true, name: true, category: true }
    });
    console.log(`✅ 设备API数据: ${equipment.length} 个设备`);

    console.log('\n🎉 数据库连接修复成功！现在API应该可以正常工作了。');

  } catch (error) {
    console.log('\n❌ 连接仍有问题:', error.message);
    console.log('💡 请确认已修改 .env 文件中的 DATABASE_URL');
  } finally {
    await prisma.$disconnect();
  }
}

verifyFix().catch(console.error);
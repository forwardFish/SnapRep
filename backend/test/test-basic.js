const { PrismaClient } = require('@prisma/client');

async function testBasicFunctionality() {
  console.log('🔍 开始基本功能测试...\n');

  const prisma = new PrismaClient();
  let testsPassed = 0;
  let testsFailed = 0;

  // 测试1: Prisma客户端连接
  try {
    console.log('1️⃣ 测试Prisma客户端连接...');
    await prisma.$connect();
    console.log('   ✅ Prisma客户端连接成功');
    testsPassed++;
  } catch (error) {
    console.log('   ❌ Prisma连接失败:', error.message);
    testsFailed++;
    return;
  }

  // 测试2: 查询场景数据
  try {
    console.log('\n2️⃣ 测试场景数据查询...');
    const scenarios = await prisma.scenario.findMany({
      take: 3,
      select: {
        id: true,
        code: true,
        name: true,
        isActive: true
      }
    });
    console.log(`   ✅ 场景查询成功，找到 ${scenarios.length} 个场景`);
    scenarios.forEach((scenario, index) => {
      console.log(`      ${index + 1}. ${scenario.code}: ${scenario.name} (${scenario.isActive ? '启用' : '禁用'})`);
    });
    testsPassed++;
  } catch (error) {
    console.log('   ❌ 场景查询失败:', error.message);
    testsFailed++;
  }

  // 测试3: 查询设备数据
  try {
    console.log('\n3️⃣ 测试设备数据查询...');
    const equipment = await prisma.equipment.findMany({
      take: 3,
      select: {
        id: true,
        code: true,
        name: true,
        category: true
      }
    });
    console.log(`   ✅ 设备查询成功，找到 ${equipment.length} 个设备`);
    equipment.forEach((item, index) => {
      console.log(`      ${index + 1}. ${item.code}: ${item.name} (${item.category})`);
    });
    testsPassed++;
  } catch (error) {
    console.log('   ❌ 设备查询失败:', error.message);
    testsFailed++;
  }

  // 测试4: 查询练习数据
  try {
    console.log('\n4️⃣ 测试练习数据查询...');
    const exercises = await prisma.exercise.findMany({
      take: 3,
      select: {
        id: true,
        code: true,
        name: true,
        primaryMuscle: true,
        difficulty: true
      }
    });
    console.log(`   ✅ 练习查询成功，找到 ${exercises.length} 个练习`);
    exercises.forEach((exercise, index) => {
      console.log(`      ${index + 1}. ${exercise.code}: ${exercise.name} (${exercise.primaryMuscle}/${exercise.difficulty})`);
    });
    testsPassed++;
  } catch (error) {
    console.log('   ❌ 练习查询失败:', error.message);
    testsFailed++;
  }

  // 测试5: 数据库写入测试
  try {
    console.log('\n5️⃣ 测试数据库写入（创建测试用户）...');
    const testUser = await prisma.user.create({
      data: {
        id: `test-${Date.now()}`,
        email: `test-${Date.now()}@test.com`,
        name: 'Test User',
        password: 'test-password'
      }
    });
    console.log(`   ✅ 用户创建成功: ${testUser.name} (${testUser.email})`);

    // 立即删除测试用户
    await prisma.user.delete({
      where: { id: testUser.id }
    });
    console.log(`   ✅ 测试用户已清理`);
    testsPassed++;
  } catch (error) {
    console.log('   ❌ 用户创建失败:', error.message);
    testsFailed++;
  }

  await prisma.$disconnect();

  // 总结
  console.log('\n📊 基本功能测试结果:');
  console.log(`   ✅ 通过: ${testsPassed}`);
  console.log(`   ❌ 失败: ${testsFailed}`);

  if (testsFailed === 0) {
    console.log('\n🎉 所有基本功能测试通过！数据库连接和基本操作正常。');
  } else {
    console.log('\n⚠️  发现问题，需要检查数据库配置或数据。');
  }
}

// 运行测试
testBasicFunctionality().catch(console.error);
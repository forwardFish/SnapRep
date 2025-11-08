#!/usr/bin/env node

/**
 * 检查数据库中的测试数据是否完整
 * 分析为什么推荐API可能失败
 */

const { PrismaClient } = require('@prisma/client');

async function analyzeTestData() {
  console.log('🔍 分析测试数据完整性...\n');

  const prisma = new PrismaClient();

  try {
    console.log('📊 数据统计:');

    // 检查各表的记录数
    const scenarios = await prisma.scenario.count();
    console.log(`Scenarios (场景): ${scenarios}`);

    const equipment = await prisma.equipment.count();
    console.log(`Equipment (器材): ${equipment}`);

    const exercises = await prisma.exercise.count();
    console.log(`Exercises (动作): ${exercises}`);

    const exerciseEquipment = await prisma.exerciseEquipment.count();
    console.log(`ExerciseEquipment (动作-器材关系): ${exerciseEquipment}`);

    const exerciseScenarios = await prisma.exerciseScenario.count();
    console.log(`ExerciseScenarios (动作-场景关系): ${exerciseScenarios}`);

    console.log('\n🔍 详细数据检查:');

    // 检查特定的测试数据
    console.log('\n1. 检查 hands_free 器材:');
    const handsFreee = await prisma.equipment.findFirst({
      where: { code: 'hands_free' }
    });
    console.log(handsFreee ? `✅ 找到 hands_free 器材: ${handsFreee.name}` : '❌ 未找到 hands_free 器材');

    console.log('\n2. 检查 STRETCH 意图的动作:');
    const stretchExercises = await prisma.exercise.findMany({
      where: { intentType: 'STRETCH' },
      take: 3
    });
    console.log(`✅ STRETCH 动作数量: ${stretchExercises.length}`);
    stretchExercises.forEach(ex => console.log(`   - ${ex.code}: ${ex.name?.name || ex.name}`));

    console.log('\n3. 检查动作-器材关联:');
    const exerciseWithEquipment = await prisma.exerciseEquipment.findMany({
      where: {
        equipment: { code: 'hands_free' }
      },
      include: {
        exercise: true,
        equipment: true
      },
      take: 3
    });
    console.log(`✅ hands_free 相关动作: ${exerciseWithEquipment.length}`);
    exerciseWithEquipment.forEach(rel =>
      console.log(`   - ${rel.exercise.code}: ${rel.exercise.name?.name || rel.exercise.name}`)
    );

    console.log('\n4. 检查是否有 STRETCH + hands_free 的动作:');
    const specificExercises = await prisma.exercise.findMany({
      where: {
        intentType: 'STRETCH',
        exerciseEquipment: {
          some: {
            equipment: { code: 'hands_free' }
          }
        }
      },
      take: 3
    });
    console.log(`✅ STRETCH + hands_free 动作数量: ${specificExercises.length}`);

    if (specificExercises.length === 0) {
      console.log('\n❌ 关键问题发现: 没有找到 STRETCH + hands_free 的动作!');
      console.log('这解释了为什么推荐API返回500错误');
      console.log('\n🔧 解决方案: 需要添加测试数据或检查数据关联关系');
    } else {
      console.log('\n✅ 数据存在，问题可能在其他地方');
      specificExercises.forEach(ex =>
        console.log(`   - ${ex.code}: ${ex.name?.name || ex.name}`)
      );
    }

    console.log('\n5. 检查枚举值:');
    const allIntents = await prisma.exercise.findMany({
      select: { intentType: true },
      distinct: ['intentType']
    });
    console.log('数据库中的 IntentType 值:', allIntents.map(e => e.intentType));

  } catch (error) {
    console.log('❌ 数据检查失败:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  analyzeTestData().catch(console.error);
}
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createTestThemeWeek() {
  try {
    console.log('🔧 Creating test theme week data...');

    // 计算本周一和下周一的时间
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay() + 1); // 本周一
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7); // 下周一
    endOfWeek.setHours(0, 0, 0, 0);

    console.log(`📅 Week range: ${startOfWeek.toISOString()} to ${endOfWeek.toISOString()}`);

    // 检查是否已存在活跃的主题周
    const existingActiveThemeWeek = await prisma.themeWeek.findFirst({
      where: {
        status: 'ACTIVE',
        startDate: { lte: now },
        endDate: { gte: now },
      },
    });

    if (existingActiveThemeWeek) {
      console.log('✅ Active theme week already exists:', existingActiveThemeWeek);
      return existingActiveThemeWeek;
    }

    // 创建测试主题周
    const themeWeek = await prisma.themeWeek.create({
      data: {
        id: 'tw_test_current_week',
        title: '办公室健身挑战周',
        code: 'OFFICE_FITNESS_WEEK',
        description: '利用办公室常见物品进行健身训练，提升工作期间的身体活力',
        equipmentCode: 'OFFICE_CHAIR',
        targetExerciseCount: 5,
        startDate: startOfWeek,
        endDate: endOfWeek,
        rewardType: 'POINTS',
        rewardData: {
          points: 100,
          badge: '办公室健身达人',
        },
        status: 'ACTIVE',
        isVisible: true,
      },
    });

    console.log('✅ Test theme week created successfully:');
    console.log(JSON.stringify(themeWeek, null, 2));

    // 验证查询
    const currentThemeWeek = await prisma.themeWeek.findFirst({
      where: {
        startDate: { lte: now },
        endDate: { gte: now },
        status: 'ACTIVE',
      },
      orderBy: { startDate: 'desc' },
    });

    console.log('🔍 Verification - Current theme week query result:');
    console.log(JSON.stringify(currentThemeWeek, null, 2));

    return themeWeek;
  } catch (error) {
    console.error('❌ Error creating test theme week:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

createTestThemeWeek()
  .then(() => {
    console.log('✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

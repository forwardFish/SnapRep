const { PrismaClient } = require('@prisma/client');

async function insertTestThemeWeek() {
  const prisma = new PrismaClient();

  try {
    console.log('🔄 Inserting test theme week data...');

    // Calculate dates relative to today
    const now = new Date();
    const startDate = new Date(now);
    startDate.setDate(now.getDate() - 2); // Started 2 days ago

    const endDate = new Date(now);
    endDate.setDate(now.getDate() + 5); // Ends in 5 days

    console.log(`📅 Creating theme week from ${startDate.toISOString()} to ${endDate.toISOString()}`);

    const themeWeek = await prisma.themeWeek.create({
      data: {
        id: 'tw_test_current_week',
        title: '办公室健身挑战周',
        code: 'OFFICE_FITNESS_WEEK',
        description: '利用办公室常见物品进行健身训练，提升工作期间的身体活力',
        equipmentCode: 'OFFICE_CHAIR',
        targetExerciseCount: 5,
        startDate: startDate,
        endDate: endDate,
        rewardType: 'POINTS',
        rewardData: {
          points: 100,
          badge: '办公室健身达人'
        },
        status: 'ACTIVE',
        isVisible: true,
        totalParticipants: 0,
        totalCompletions: 0,
        completionRate: 0.0,
      }
    });

    console.log('✅ Theme week created successfully:');
    console.log(`   - ID: ${themeWeek.id}`);
    console.log(`   - Title: ${themeWeek.title}`);
    console.log(`   - Code: ${themeWeek.code}`);
    console.log(`   - Status: ${themeWeek.status}`);
    console.log(`   - Visible: ${themeWeek.isVisible}`);
    console.log(`   - Start: ${themeWeek.startDate.toISOString()}`);
    console.log(`   - End: ${themeWeek.endDate.toISOString()}`);

    // Verify the data can be queried
    console.log('🔍 Testing query...');
    const currentThemeWeek = await prisma.themeWeek.findFirst({
      where: {
        status: 'ACTIVE',
        isVisible: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
    });

    if (currentThemeWeek) {
      console.log(`✅ Query successful: Found ${currentThemeWeek.code}`);
    } else {
      console.log('❌ Query failed: No theme week found');
    }

    await prisma.$disconnect();
    console.log('✅ Database operation completed');

  } catch (error) {
    console.error('❌ Error inserting theme week:', error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

insertTestThemeWeek().catch(console.error);
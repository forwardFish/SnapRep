const { PrismaClient } = require('@prisma/client');

async function testDatabaseDirectly() {
  const prisma = new PrismaClient({
    log: ['query'],
  });

  try {
    console.log('🔍 Testing database directly with Prisma...');

    // Check database connection
    await prisma.$connect();
    console.log('✅ Database connected successfully');

    // Get all theme weeks to see what's in database
    const allThemeWeeks = await prisma.themeWeek.findMany({
      select: {
        id: true,
        title: true,
        code: true,
        status: true,
        isVisible: true,
        startDate: true,
        endDate: true,
        createdAt: true,
      },
      orderBy: {
        startDate: 'desc',
      },
    });

    console.log(`📊 Found ${allThemeWeeks.length} total theme weeks in database:`);
    allThemeWeeks.forEach((week, index) => {
      const now = new Date();
      const isInDateRange = week.startDate <= now && week.endDate >= now;
      const isActive = week.status === 'ACTIVE';
      const isVisible = week.isVisible === true;

      console.log(`${index + 1}. ${week.code}:`);
      console.log(`   - ID: ${week.id}`);
      console.log(`   - Title: ${week.title}`);
      console.log(`   - Status: ${week.status} (active: ${isActive})`);
      console.log(`   - Visible: ${week.isVisible} (visible: ${isVisible})`);
      console.log(`   - Start: ${week.startDate.toISOString()}`);
      console.log(`   - End: ${week.endDate.toISOString()}`);
      console.log(`   - In date range: ${isInDateRange}`);
      console.log(`   - Matches all criteria: ${isActive && isVisible && isInDateRange}`);
      console.log('');
    });

    // Test the exact query that should find current theme week
    const now = new Date();
    console.log(`🔍 Testing exact query for current time: ${now.toISOString()}`);

    const result = await prisma.themeWeek.findFirst({
      where: {
        status: 'ACTIVE',
        isVisible: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: {
        startDate: 'desc',
      },
    });

    if (result) {
      console.log(`✅ Query result found: ${result.code} (${result.title})`);
    } else {
      console.log('❌ Query result: null');
    }

    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Database test failed:', error);
    await prisma.$disconnect();
  }
}

testDatabaseDirectly().catch(console.error);
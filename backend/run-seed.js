// SnapRep Seed Execution Script
// 直接执行seed数据到Supabase数据库

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function executeSeed() {
  console.log('🌱 开始执行SnapRep数据库种子数据...');

  try {
    // 清理现有数据（按依赖关系倒序删除）
    console.log('🧹 清理现有数据...');
    await prisma.deeplinkClick.deleteMany();
    await prisma.deeplink.deleteMany();
    await prisma.themeWeekParticipation.deleteMany();
    await prisma.themeWeek.deleteMany();
    await prisma.userPreference.deleteMany();
    await prisma.rarityTable.deleteMany();
    await prisma.dailyTraining.deleteMany();
    await prisma.shareCard.deleteMany();
    await prisma.sessionExercise.deleteMany();
    await prisma.workoutSession.deleteMany();
    await prisma.exerciseEquipment.deleteMany();
    await prisma.exerciseScenario.deleteMany();
    await prisma.exercise.deleteMany();
    await prisma.equipment.deleteMany();
    await prisma.scenario.deleteMany();
    await prisma.user.deleteMany();

    console.log('✅ 数据清理完成');

    // 1. 插入场景数据
    console.log('📍 插入场景数据...');
    await prisma.scenario.createMany({
      data: [
        {
          code: 'office',
          name: 'Office',
          noiseTolerance: 'SILENT',
          spaceRequirement: 'SMALL',
          iconUrl: '/icons/office.svg',
          isActive: true,
        },
        {
          code: 'home',
          name: 'Home',
          noiseTolerance: 'NORMAL',
          spaceRequirement: 'MEDIUM',
          iconUrl: '/icons/home.svg',
          isActive: true,
        },
        {
          code: 'gym',
          name: 'Gym',
          noiseTolerance: 'NORMAL',
          spaceRequirement: 'LARGE',
          iconUrl: '/icons/gym.svg',
          isActive: true,
        },
        {
          code: 'park',
          name: 'Park',
          noiseTolerance: 'NORMAL',
          spaceRequirement: 'LARGE',
          iconUrl: '/icons/park.svg',
          isActive: true,
        },
      ],
    });

    // 2. 插入器材数据
    console.log('🪑 插入器材数据...');
    await prisma.equipment.createMany({
      data: [
        {
          code: 'none',
          name: 'No Equipment',
          category: 'NONE',
          recognizable: false,
          recognitionLabels: [],
          recognitionConfidence: 0.85,
          iconUrl: '/equipment/none.jpg',
          displayOrder: 0,
          isActive: true,
        },
        {
          code: 'chair',
          name: 'Chair',
          category: 'FURNITURE',
          recognizable: true,
          recognitionLabels: ['chair', 'stool', 'seat'],
          recognitionConfidence: 0.85,
          iconUrl: '/equipment/chair.jpg',
          displayOrder: 1,
          isActive: true,
        },
        {
          code: 'wall',
          name: 'Wall',
          category: 'WALL',
          recognizable: true,
          recognitionLabels: ['wall'],
          recognitionConfidence: 0.85,
          iconUrl: '/equipment/wall.jpg',
          displayOrder: 2,
          isActive: true,
        },
        {
          code: 'bottle',
          name: 'Water Bottle',
          category: 'BOTTLE',
          recognizable: true,
          recognitionLabels: ['bottle', 'water bottle'],
          recognitionConfidence: 0.85,
          iconUrl: '/equipment/bottle.jpg',
          displayOrder: 3,
          isActive: true,
        },
      ],
    });

    // 3. 插入练习数据
    console.log('💪 插入练习数据...');

    const wallChestOpener = await prisma.exercise.create({
      data: {
        code: 'wall_chest_opener',
        name: 'Wall Chest Opener',
        primaryMuscle: 'NECK_SHOULDER',
        secondaryMuscles: ['CHEST', 'SHOULDERS'],
        intentType: 'STRETCH',
        difficulty: 'GREEN',
        description: {
          keyPoints: ['Keep spine neutral', 'Arms extended upward', 'Breathe naturally'],
          steps: ['Stand against wall', 'Raise arms overhead', 'Hold for 20 seconds'],
          warnings: ['Keep neck neutral, no hyperextension', 'Lower shoulders, no shrugging']
        },
        defaultDuration: 20,
        defaultSets: 1,
        durationType: 'TIME',
        demoImageUrl: '/demos/wall_chest_opener.jpg',
        tags: ['standing', 'wall', 'stretch', 'silent', 'small_space'],
        isActive: true,
      },
    });

    const chairDips = await prisma.exercise.create({
      data: {
        code: 'chair_dips',
        name: 'Chair Dips',
        primaryMuscle: 'ARMS',
        secondaryMuscles: ['CHEST', 'SHOULDERS'],
        intentType: 'STRENGTH',
        difficulty: 'BLUE',
        description: {
          keyPoints: ['Keep body close to chair', 'Lower with control', 'Push through palms'],
          steps: ['Sit on chair edge', 'Hands beside hips', 'Lower body down', 'Push back up'],
          warnings: ['No shoulder impingement history', 'Ensure chair stability']
        },
        defaultDuration: 12,
        defaultSets: 3,
        durationType: 'REPS',
        demoImageUrl: '/demos/chair_dips.jpg',
        tags: ['sitting', 'chair', 'strength', 'arms'],
        isActive: true,
      },
    });

    const bottlePress = await prisma.exercise.create({
      data: {
        code: 'bottle_overhead_press',
        name: 'Bottle Overhead Press',
        primaryMuscle: 'SHOULDERS',
        secondaryMuscles: ['ARMS', 'CORE'],
        intentType: 'MODERATE',
        difficulty: 'GREEN',
        description: {
          keyPoints: ['Keep core engaged', 'Press straight overhead', 'Control the weight'],
          steps: ['Hold bottle with both hands', 'Press overhead', 'Lower with control', 'Repeat'],
          warnings: ['Use filled water bottle (500ml-1L)', 'Ensure cap is tightly closed']
        },
        defaultDuration: 10,
        defaultSets: 2,
        durationType: 'REPS',
        demoImageUrl: '/demos/bottle_press.jpg',
        tags: ['standing', 'bottle', 'strength', 'shoulders'],
        isActive: true,
      },
    });

    const bodyweightSquat = await prisma.exercise.create({
      data: {
        code: 'bodyweight_squat',
        name: 'Bodyweight Squat',
        primaryMuscle: 'LEGS',
        secondaryMuscles: ['GLUTES', 'CORE'],
        intentType: 'STRENGTH',
        difficulty: 'GREEN',
        description: {
          keyPoints: ['Keep chest up', 'Knees track over toes', 'Full range of motion'],
          steps: ['Stand with feet shoulder-width apart', 'Lower by bending knees', 'Descend until thighs parallel', 'Push through heels to stand'],
          warnings: ['Avoid knee cave', 'Keep weight on heels']
        },
        defaultDuration: 15,
        defaultSets: 3,
        durationType: 'REPS',
        demoImageUrl: '/demos/bodyweight_squat.jpg',
        tags: ['standing', 'bodyweight', 'strength', 'legs'],
        isActive: true,
      },
    });

    // 4. 获取场景和器材数据用于关联
    const scenarios = await prisma.scenario.findMany();
    const equipment = await prisma.equipment.findMany();

    const officeScenario = scenarios.find(s => s.code === 'office');
    const homeScenario = scenarios.find(s => s.code === 'home');
    const gymScenario = scenarios.find(s => s.code === 'gym');
    const parkScenario = scenarios.find(s => s.code === 'park');

    const wallEquipment = equipment.find(e => e.code === 'wall');
    const chairEquipment = equipment.find(e => e.code === 'chair');
    const bottleEquipment = equipment.find(e => e.code === 'bottle');
    const noneEquipment = equipment.find(e => e.code === 'none');

    // 5. 创建练习-场景关联
    console.log('🔗 创建练习-场景关联...');
    await prisma.exerciseScenario.createMany({
      data: [
        { exerciseId: wallChestOpener.id, scenarioId: officeScenario.id },
        { exerciseId: wallChestOpener.id, scenarioId: homeScenario.id },
        { exerciseId: chairDips.id, scenarioId: officeScenario.id },
        { exerciseId: chairDips.id, scenarioId: homeScenario.id },
        { exerciseId: bottlePress.id, scenarioId: homeScenario.id },
        { exerciseId: bottlePress.id, scenarioId: gymScenario.id },
        { exerciseId: bottlePress.id, scenarioId: parkScenario.id },
        { exerciseId: bodyweightSquat.id, scenarioId: officeScenario.id },
        { exerciseId: bodyweightSquat.id, scenarioId: homeScenario.id },
        { exerciseId: bodyweightSquat.id, scenarioId: gymScenario.id },
        { exerciseId: bodyweightSquat.id, scenarioId: parkScenario.id },
      ],
    });

    // 6. 创建练习-器材关联
    console.log('🛠️ 创建练习-器材关联...');
    await prisma.exerciseEquipment.createMany({
      data: [
        { exerciseId: wallChestOpener.id, equipmentId: wallEquipment.id, isRequired: true },
        { exerciseId: chairDips.id, equipmentId: chairEquipment.id, isRequired: true },
        { exerciseId: bottlePress.id, equipmentId: bottleEquipment.id, isRequired: true },
        { exerciseId: bodyweightSquat.id, equipmentId: noneEquipment.id, isRequired: true },
      ],
    });

    // 7. 创建测试用户
    console.log('👤 创建测试用户...');
    const testUser = await prisma.user.create({
      data: {
        id: 'test-user-uuid-v3',
        email: 'test@snaprep.app',
        name: 'Test User',
        avatarUrl: '/avatars/test.jpg',
        language: 'zh',
        theme: 'auto',
        totalWorkouts: 0,
        totalDurationSec: 0,
        currentStreak: 0,
        longestStreak: 0,
        preferredIntents: ['STRETCH', 'MODERATE'],
        preferredDifficulty: 'GREEN',
        preferredDuration: 300,
        avoidEquipment: [],
        streakReminder: true,
        themeWeekReminder: true,
        hideRealPhotos: true,
        autoBlurFaces: true,
        allowDataSync: false,
      },
    });

    // 8. 创建稀有度表数据
    console.log('💎 创建稀有度表数据...');
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay() + 1);
    weekStart.setHours(0, 0, 0, 0);

    await prisma.rarityTable.createMany({
      data: [
        {
          equipmentId: noneEquipment.id,
          equipmentCode: 'none',
          weekStart,
          rarityScore: 0.95,
          rarityLevel: 'COMMON',
          dataSource: 'WEEKLY_TABLE',
        },
        {
          equipmentId: chairEquipment.id,
          equipmentCode: 'chair',
          weekStart,
          rarityScore: 0.65,
          rarityLevel: 'COMMON',
          dataSource: 'WEEKLY_TABLE',
        },
        {
          equipmentId: wallEquipment.id,
          equipmentCode: 'wall',
          weekStart,
          rarityScore: 0.45,
          rarityLevel: 'UNCOMMON',
          dataSource: 'WEEKLY_TABLE',
        },
        {
          equipmentId: bottleEquipment.id,
          equipmentCode: 'bottle',
          weekStart,
          rarityScore: 0.25,
          rarityLevel: 'UNCOMMON',
          dataSource: 'WEEKLY_TABLE',
        },
      ],
    });

    console.log('✅ 种子数据执行成功！');
    console.log(`📊 已创建:`);
    console.log(`   - 4 个场景 (office, home, gym, park)`);
    console.log(`   - 4 种器材 (none, chair, wall, bottle)`);
    console.log(`   - 4 个练习动作`);
    console.log(`   - 10 个练习-场景关联`);
    console.log(`   - 4 个练习-器材关联`);
    console.log(`   - 1 个测试用户`);
    console.log(`   - 4 条稀有度表记录`);
    console.log('🚀 数据库准备就绪！');

  } catch (error) {
    console.error('❌ 种子数据执行失败:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// 执行种子数据
executeSeed();
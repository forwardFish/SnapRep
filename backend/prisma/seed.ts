// SnapRep Seed Data v3.0 - Production Ready
// Based on current Prisma schema and mock data from service layers

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding SnapRep database v3.0...');

  // Clean existing data (in reverse dependency order)
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

  console.log('✅ Cleared existing data');

  // 1. Seed Scenarios (based on mock data from scenarios.dao.ts)
  console.log('📍 Seeding scenarios...');
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

  // 2. Seed Equipment (based on mock data from equipment.dao.ts)
  console.log('🪑 Seeding equipment...');
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

  // 3. Seed Exercises
  console.log('💪 Seeding exercises...');

  // Wall Chest Opener
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

  // Chair Dips
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

  // Bottle Overhead Press
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

  // Bodyweight Squat
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

  // 4. Link Exercises to Scenarios
  console.log('🔗 Linking exercises to scenarios...');
  const scenarios = await prisma.scenario.findMany();
  const officeScenario = scenarios.find(s => s.code === 'office')!;
  const homeScenario = scenarios.find(s => s.code === 'home')!;
  const gymScenario = scenarios.find(s => s.code === 'gym')!;
  const parkScenario = scenarios.find(s => s.code === 'park')!;

  await prisma.exerciseScenario.createMany({
    data: [
      // Wall Chest Opener - suitable for office and home
      { exerciseId: wallChestOpener.id, scenarioId: officeScenario.id },
      { exerciseId: wallChestOpener.id, scenarioId: homeScenario.id },

      // Chair Dips - suitable for office and home
      { exerciseId: chairDips.id, scenarioId: officeScenario.id },
      { exerciseId: chairDips.id, scenarioId: homeScenario.id },

      // Bottle Press - suitable for home, gym, park
      { exerciseId: bottlePress.id, scenarioId: homeScenario.id },
      { exerciseId: bottlePress.id, scenarioId: gymScenario.id },
      { exerciseId: bottlePress.id, scenarioId: parkScenario.id },

      // Bodyweight Squat - suitable for all scenarios
      { exerciseId: bodyweightSquat.id, scenarioId: officeScenario.id },
      { exerciseId: bodyweightSquat.id, scenarioId: homeScenario.id },
      { exerciseId: bodyweightSquat.id, scenarioId: gymScenario.id },
      { exerciseId: bodyweightSquat.id, scenarioId: parkScenario.id },
    ],
  });

  // 5. Link Exercises to Equipment
  console.log('🛠️ Linking exercises to equipment...');
  const equipment = await prisma.equipment.findMany();
  const wallEquipment = equipment.find(e => e.code === 'wall')!;
  const chairEquipment = equipment.find(e => e.code === 'chair')!;
  const bottleEquipment = equipment.find(e => e.code === 'bottle')!;
  const noneEquipment = equipment.find(e => e.code === 'none')!;

  await prisma.exerciseEquipment.createMany({
    data: [
      // Wall Chest Opener requires wall
      {
        exerciseId: wallChestOpener.id,
        equipmentId: wallEquipment.id,
        isRequired: true,
      },
      // Chair Dips requires chair
      {
        exerciseId: chairDips.id,
        equipmentId: chairEquipment.id,
        isRequired: true,
      },
      // Bottle Press requires bottle
      {
        exerciseId: bottlePress.id,
        equipmentId: bottleEquipment.id,
        isRequired: true,
      },
      // Bodyweight Squat requires no equipment
      {
        exerciseId: bodyweightSquat.id,
        equipmentId: noneEquipment.id,
        isRequired: true,
      },
    ],
  });

  // 6. Create test user (for development)
  console.log('👤 Creating test user...');
  const testUser = await prisma.user.create({
    data: {
      id: 'test-user-uuid-v3', // In real app, this would be Supabase Auth UUID
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
      preferredDuration: 300, // 5 minutes
      avoidEquipment: [],
      streakReminder: true,
      themeWeekReminder: true,
      hideRealPhotos: true,
      autoBlurFaces: true,
      allowDataSync: false,
    },
  });

  // 7. Create sample rarity table data
  console.log('💎 Creating sample rarity table...');
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - now.getDay() + 1); // Get Monday of current week
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

  console.log('✅ Seed data created successfully!');
  console.log(`📊 Created:`);
  console.log(`   - 4 scenarios (office, home, gym, park)`);
  console.log(`   - 4 equipment types (none, chair, wall, bottle)`);
  console.log(`   - 4 exercises with descriptions`);
  console.log(`   - 10 exercise-scenario links`);
  console.log(`   - 4 exercise-equipment links`);
  console.log(`   - 1 test user`);
  console.log(`   - 4 rarity table entries`);
  console.log('🚀 Database ready for development!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
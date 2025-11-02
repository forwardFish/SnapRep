// SnapRep Seed Data (MVP v2.0)
// Based on docs/db_v2_mvp.md seed examples

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding SnapRep database...');

  // Clean existing data (in reverse dependency order)
  await prisma.resultCard.deleteMany();
  await prisma.sessionExercise.deleteMany();
  await prisma.workoutSessionEquipment.deleteMany();
  await prisma.workoutSessionScenario.deleteMany();
  await prisma.workoutSession.deleteMany();
  await prisma.userPreference.deleteMany();
  await prisma.user.deleteMany();
  await prisma.exerciseI18n.deleteMany();
  await prisma.exerciseEquipment.deleteMany();
  await prisma.exerciseScenario.deleteMany();
  await prisma.exercise.deleteMany();
  await prisma.equipment.deleteMany();
  await prisma.scenario.deleteMany();

  console.log('✅ Cleared existing data');

  // 1. Seed Scenarios
  console.log('📍 Seeding scenarios...');
  await prisma.scenario.createMany({
    data: [
      {
        code: 'office',
        nameEn: 'Office',
        nameZh: '办公室',
        noiseTolerance: 'SILENT',
        spaceRequirement: 'SMALL',
        iconUrl: '/assets/scenarios/office.svg',
        displayOrder: 1,
      },
      {
        code: 'home',
        nameEn: 'Living Room',
        nameZh: '客厅',
        noiseTolerance: 'NORMAL',
        spaceRequirement: 'MEDIUM',
        iconUrl: '/assets/scenarios/home.svg',
        displayOrder: 2,
      },
      {
        code: 'travel',
        nameEn: 'Travel / Hotel',
        nameZh: '旅途/酒店',
        noiseTolerance: 'QUIET',
        spaceRequirement: 'SMALL',
        iconUrl: '/assets/scenarios/travel.svg',
        displayOrder: 3,
      },
      {
        code: 'bedroom',
        nameEn: 'Bedroom',
        nameZh: '卧室',
        noiseTolerance: 'QUIET',
        spaceRequirement: 'MEDIUM',
        iconUrl: '/assets/scenarios/bedroom.svg',
        displayOrder: 4,
      },
    ],
  });

  // 2. Seed Equipment
  console.log('🪑 Seeding equipment...');
  await prisma.equipment.createMany({
    data: [
      {
        code: 'none',
        nameEn: 'No Equipment',
        nameZh: '空手',
        category: 'NONE',
        iconUrl: '/assets/equipment/none.svg',
        safetyGuidelines: {
          en: 'Use your body weight only. Ensure proper form.',
          zh: '仅使用自身体重，确保动作标准。'
        },
        displayOrder: 1,
      },
      {
        code: 'chair',
        nameEn: 'Chair',
        nameZh: '椅子',
        category: 'FURNITURE',
        isRecognizable: true,
        recognitionLabels: ['chair', 'stool', 'seat'],
        iconUrl: '/assets/equipment/chair.svg',
        safetyGuidelines: {
          en: 'Use a stable chair that can support your body weight. Ensure chair is on flat surface.',
          zh: '使用稳固椅子，能承受体重。确保椅子在平坦表面上。',
        },
        properties: {
          weightRange: '80-150kg support',
          sizeRequirement: '40-50cm height',
          stability: 'Must be stable, no wheels'
        },
        displayOrder: 2,
      },
      {
        code: 'wall',
        nameEn: 'Wall',
        nameZh: '墙面',
        category: 'WALL',
        isRecognizable: true,
        recognitionLabels: ['wall'],
        iconUrl: '/assets/equipment/wall.svg',
        safetyGuidelines: {
          en: 'Use a flat, sturdy wall. Ensure no sharp edges or obstacles nearby.',
          zh: '使用平整、坚固的墙面。确保附近无尖锐边缘或障碍物。',
        },
        properties: {
          surface: 'Flat and stable',
          space: 'Clear 1m radius'
        },
        displayOrder: 3,
      },
      {
        code: 'bottle',
        nameEn: 'Water Bottle',
        nameZh: '水瓶',
        category: 'BOTTLE',
        isRecognizable: true,
        recognitionLabels: ['bottle', 'water bottle'],
        iconUrl: '/assets/equipment/bottle.svg',
        safetyGuidelines: {
          en: 'Use a filled water bottle (500ml-1L). Ensure cap is tightly closed.',
          zh: '使用装满水的水瓶(500ml-1L)。确保瓶盖拧紧。',
        },
        properties: {
          weightRange: '0.5-1kg',
          size: '500ml-1L capacity'
        },
        displayOrder: 4,
      },
      {
        code: 'backpack',
        nameEn: 'Backpack',
        nameZh: '背包',
        category: 'BAG',
        isRecognizable: true,
        recognitionLabels: ['backpack', 'bag'],
        iconUrl: '/assets/equipment/backpack.svg',
        safetyGuidelines: {
          en: 'Use a sturdy backpack. Adjust weight according to your fitness level.',
          zh: '使用结实的背包。根据健身水平调整重量。',
        },
        properties: {
          weightRange: '2-10kg adjustable',
          size: 'Standard backpack'
        },
        displayOrder: 5,
      },
    ],
  });

  // 3. Seed Exercise
  console.log('💪 Seeding exercises...');
  const exercise = await prisma.exercise.create({
    data: {
      code: 'wall_chest_opener',
      nameEn: 'Wall Chest Opener',
      primaryMuscle: 'NECK_SHOULDER',
      secondaryMuscles: ['CHEST', 'SHOULDERS'],
      intentType: 'STRETCH',
      difficulty: 'BEGINNER',
      spaceRequirement: 'SMALL',
      isSilent: true,
      noiseLevel: 'SILENT',
      defaultDuration: 20,
      defaultSets: 1,
      durationFormat: 'TIME',
      tags: ['standing', 'wall', 'stretch', 'silent', 'small_space'],
      popularityScore: 0.85,
      safetyScore: 0.95,
      effectivenessScore: 0.8,
      demoImageUrl: 'https://placeholder.supabase.co/storage/v1/object/public/exercise-media/wall_chest_opener.jpg',
    },
  });

  const chairDips = await prisma.exercise.create({
    data: {
      code: 'chair_dips',
      nameEn: 'Chair Dips',
      primaryMuscle: 'ARMS',
      secondaryMuscles: ['CHEST', 'SHOULDERS'],
      intentType: 'STRENGTH',
      difficulty: 'INTERMEDIATE',
      spaceRequirement: 'SMALL',
      isSilent: false,
      noiseLevel: 'QUIET',
      defaultDuration: 12,
      defaultSets: 3,
      durationFormat: 'REPS',
      tags: ['sitting', 'chair', 'strength', 'arms'],
      popularityScore: 0.9,
      safetyScore: 0.85,
      effectivenessScore: 0.9,
      demoImageUrl: 'https://placeholder.supabase.co/storage/v1/object/public/exercise-media/chair_dips.jpg',
    },
  });

  const bottlePress = await prisma.exercise.create({
    data: {
      code: 'bottle_overhead_press',
      nameEn: 'Bottle Overhead Press',
      primaryMuscle: 'SHOULDERS',
      secondaryMuscles: ['ARMS', 'CORE'],
      intentType: 'MODERATE',
      difficulty: 'BEGINNER',
      spaceRequirement: 'SMALL',
      isSilent: true,
      noiseLevel: 'SILENT',
      defaultDuration: 10,
      defaultSets: 2,
      durationFormat: 'REPS',
      tags: ['standing', 'bottle', 'strength', 'shoulders'],
      popularityScore: 0.75,
      safetyScore: 0.9,
      effectivenessScore: 0.8,
      demoImageUrl: 'https://placeholder.supabase.co/storage/v1/object/public/exercise-media/bottle_press.jpg',
    },
  });

  // 4. Seed Exercise I18n
  console.log('🌐 Seeding exercise translations...');
  await prisma.exerciseI18n.createMany({
    data: [
      // Wall Chest Opener - English
      {
        exerciseId: exercise.id,
        lang: 'en',
        title: 'Wall Chest Opener',
        keyPoints: ['Keep spine neutral', 'Arms extended upward', 'Breathe naturally'],
        targetEffect: 'Relieve neck stiffness, relax shoulders',
        contraindications: ['Keep neck neutral, no hyperextension', 'Lower shoulders, no shrugging'],
        operationSteps: ['Stand against wall', 'Raise arms overhead', 'Hold for 20 seconds'],
        commonMistakes: ['Arching back too much', 'Holding breath'],
        breathingGuide: 'Inhale to prepare, exhale and hold, breathe naturally during hold',
      },
      // Wall Chest Opener - Chinese
      {
        exerciseId: exercise.id,
        lang: 'zh',
        title: '靠墙胸椎打开',
        keyPoints: ['脊柱保持中立', '双臂向上延展', '保持自然呼吸'],
        targetEffect: '缓解颈部僵硬,放松肩颈',
        contraindications: ['颈保持中立,不后仰', '肩下沉不耸肩'],
        operationSteps: ['背部贴墙站立', '双臂向上举', '保持20秒'],
        commonMistakes: ['过度拱背', '憋气'],
        breathingGuide: '吸气准备，呼气保持，持续过程中自然呼吸',
      },
      // Chair Dips - English
      {
        exerciseId: chairDips.id,
        lang: 'en',
        title: 'Chair Dips',
        keyPoints: ['Keep body close to chair', 'Lower with control', 'Push through palms'],
        targetEffect: 'Strengthen triceps, chest, and shoulders',
        contraindications: ['No shoulder impingement history', 'Ensure chair stability'],
        operationSteps: ['Sit on chair edge', 'Hands beside hips', 'Lower body down', 'Push back up'],
        commonMistakes: ['Going too low', 'Flaring elbows out'],
        breathingGuide: 'Inhale while lowering, exhale while pushing up',
      },
      // Chair Dips - Chinese
      {
        exerciseId: chairDips.id,
        lang: 'zh',
        title: '椅子臂屈伸',
        keyPoints: ['身体贴近椅子', '控制下降速度', '用手掌发力'],
        targetEffect: '增强三头肌、胸肌和肩部力量',
        contraindications: ['无肩部撞击史', '确保椅子稳定'],
        operationSteps: ['坐在椅子边缘', '双手置于臀部两侧', '身体下降', '推起回到起始位置'],
        commonMistakes: ['下降过低', '肘部外展'],
        breathingGuide: '下降时吸气，推起时呼气',
      },
    ],
  });

  // 5. Link Exercise to Scenarios
  console.log('🔗 Linking exercises to scenarios...');
  const officeScenario = await prisma.scenario.findUnique({ where: { code: 'office' } });
  const homeScenario = await prisma.scenario.findUnique({ where: { code: 'home' } });
  const travelScenario = await prisma.scenario.findUnique({ where: { code: 'travel' } });

  await prisma.exerciseScenario.createMany({
    data: [
      { exerciseId: exercise.id, scenarioId: officeScenario!.id },
      { exerciseId: exercise.id, scenarioId: homeScenario!.id },
      { exerciseId: chairDips.id, scenarioId: officeScenario!.id },
      { exerciseId: chairDips.id, scenarioId: homeScenario!.id },
      { exerciseId: bottlePress.id, scenarioId: travelScenario!.id },
      { exerciseId: bottlePress.id, scenarioId: homeScenario!.id },
    ],
  });

  // 6. Link Exercise to Equipment
  console.log('🛠️ Linking exercises to equipment...');
  const wallEquipment = await prisma.equipment.findUnique({ where: { code: 'wall' } });
  const chairEquipment = await prisma.equipment.findUnique({ where: { code: 'chair' } });
  const bottleEquipment = await prisma.equipment.findUnique({ where: { code: 'bottle' } });

  await prisma.exerciseEquipment.createMany({
    data: [
      // Wall Chest Opener requires wall
      {
        exerciseId: exercise.id,
        equipmentId: wallEquipment!.id,
        isOptional: false,  // Required
      },
      // Chair Dips requires chair
      {
        exerciseId: chairDips.id,
        equipmentId: chairEquipment!.id,
        isOptional: false,  // Required
      },
      // Bottle Press requires bottle
      {
        exerciseId: bottlePress.id,
        equipmentId: bottleEquipment!.id,
        isOptional: false,  // Required
      },
    ],
  });

  // 7. Create a test user (for development)
  console.log('👤 Creating test user...');
  const testUser = await prisma.user.create({
    data: {
      id: 'test-user-uuid', // In real app, this would be Supabase Auth UUID
      email: 'test@snaprep.app',
      nickname: 'Test User',
      language: 'EN',
      preferences: {
        create: {
          favoriteIntentTypes: ['STRETCH', 'MODERATE'],
          favoriteEquipmentCodes: ['chair', 'wall'],
          favoriteScenarioCodes: ['office', 'home'],
          favoriteMuscleParts: ['NECK_SHOULDER', 'ARMS'],
          preferredDifficulty: 'BEGINNER',
          silentModeDefault: true,
        },
      },
    },
  });

  console.log('✅ Seed data created successfully!');
  console.log(`📊 Created:`);
  console.log(`   - 4 scenarios`);
  console.log(`   - 5 equipment types`);
  console.log(`   - 3 exercises with translations`);
  console.log(`   - 6 exercise-scenario links`);
  console.log(`   - 3 exercise-equipment links`);
  console.log(`   - 1 test user with preferences`);
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
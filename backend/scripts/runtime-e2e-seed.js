const { PrismaClient } = require('@prisma/client');
const { assertRuntimeE2ESafe, redactUrl } = require('./runtime-e2e-env');

const mode = process.argv[2];
if (!['seed', 'reset'].includes(mode)) {
    console.error('Usage: node scripts/runtime-e2e-seed.js <seed|reset>');
    process.exit(2);
}

const config = assertRuntimeE2ESafe({ destructive: true });
process.env.DATABASE_URL = config.databaseUrl;
process.env.DIRECT_URL = config.directUrl || config.databaseUrl;

const prisma = new PrismaClient();

const ids = {
    userId: config.testUserId,
    scenarioId: 'stage2c-scenario-office',
    equipmentId: 'stage2c-equipment-chair',
    exerciseOneId: 'stage2c-exercise-chair-squat',
    exerciseTwoId: 'stage2c-exercise-wall-stretch',
    themeWeekId: 'stage2c-theme-chair-week',
};

async function reset() {
    await prisma.shareCard.deleteMany({ where: { userId: ids.userId } });
    await prisma.sessionExercise.deleteMany({ where: { session: { userId: ids.userId } } });
    await prisma.workoutSession.deleteMany({ where: { userId: ids.userId } });
    await prisma.themeWeekParticipation.deleteMany({ where: { userId: ids.userId } });
    await prisma.user.deleteMany({ where: { id: ids.userId } });
    await prisma.exerciseEquipment.deleteMany({
        where: { exerciseId: { in: [ids.exerciseOneId, ids.exerciseTwoId] } },
    });
    await prisma.exerciseScenario.deleteMany({
        where: { exerciseId: { in: [ids.exerciseOneId, ids.exerciseTwoId] } },
    });
    await prisma.scenarioEquipment.deleteMany({ where: { scenarioId: ids.scenarioId } });
    await prisma.exercise.deleteMany({
        where: { id: { in: [ids.exerciseOneId, ids.exerciseTwoId] } },
    });
    await prisma.equipment.deleteMany({ where: { id: ids.equipmentId } });
    await prisma.scenario.deleteMany({ where: { id: ids.scenarioId } });
    await prisma.themeWeek.deleteMany({ where: { id: ids.themeWeekId } });
}

async function seed() {
    await reset();

    await prisma.user.create({
        data: {
            id: ids.userId,
            email: config.testUserEmail,
            name: 'Stage 2C Runtime User',
        },
    });

    await prisma.scenario.create({
        data: {
            id: ids.scenarioId,
            code: 'stage2c_office',
            name: 'Stage 2C Office',
            noiseTolerance: 'QUIET',
            spaceRequirement: 'SMALL',
            iconUrl: '/test/stage2c-office.png',
        },
    });

    await prisma.equipment.create({
        data: {
            id: ids.equipmentId,
            code: 'stage2c_chair',
            name: 'Stage 2C Chair',
            category: 'FURNITURE',
            recognizable: true,
            recognitionLabels: ['chair'],
            iconUrl: '/test/stage2c-chair.png',
            displayOrder: 1,
        },
    });

    await prisma.scenarioEquipment.create({
        data: { scenarioId: ids.scenarioId, equipmentId: ids.equipmentId, isCommon: true },
    });

    const description = {
        keyPoints: ['Controlled movement'],
        steps: ['Start', 'Move', 'Finish'],
        warnings: ['Stop if painful'],
    };

    for (const exercise of [
        {
            id: ids.exerciseOneId,
            code: 'stage2c_chair_squat',
            name: 'Stage 2C Chair Squat',
            muscle: 'LEGS',
            intent: 'STRENGTH',
        },
        {
            id: ids.exerciseTwoId,
            code: 'stage2c_wall_stretch',
            name: 'Stage 2C Wall Stretch',
            muscle: 'FULL_BODY',
            intent: 'STRETCH',
        },
    ]) {
        await prisma.exercise.create({
            data: {
                id: exercise.id,
                code: exercise.code,
                name: exercise.name,
                primaryMuscle: exercise.muscle,
                intentType: exercise.intent,
                difficulty: 'GREEN',
                description,
                defaultDuration: 30,
                defaultSets: 1,
                durationType: 'TIME',
                tags: ['stage2c'],
                isActive: true,
            },
        });
        await prisma.exerciseScenario.create({
            data: { exerciseId: exercise.id, scenarioId: ids.scenarioId },
        });
        await prisma.exerciseEquipment.create({
            data: { exerciseId: exercise.id, equipmentId: ids.equipmentId, isRequired: false },
        });
    }

    const now = new Date();
    const end = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    await prisma.themeWeek.create({
        data: {
            id: ids.themeWeekId,
            code: 'stage2c_chair_week',
            title: 'Stage 2C Chair Week',
            description: 'Runtime E2E test theme week',
            equipmentCode: 'stage2c_chair',
            targetExerciseCount: 2,
            startDate: now,
            endDate: end,
            rewardType: 'badge',
            rewardData: { badge: 'stage2c' },
            status: 'ACTIVE',
            isVisible: true,
        },
    });
}

async function main() {
    console.log(`Runtime E2E ${mode} using ${redactUrl(config.databaseUrl)}`);
    if (mode === 'reset') {
        await reset();
    } else {
        await seed();
    }
    console.log(`Runtime E2E ${mode} complete.`);
}

main()
    .catch(error => {
        console.error(error.message);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

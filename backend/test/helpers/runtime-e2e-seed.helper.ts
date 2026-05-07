import { PrismaService } from 'nestjs-prisma';
import { RuntimeE2EConfig } from './runtime-e2e-env.helper';

export const runtimeE2EIds = {
    scenarioId: 'stage2c-scenario-office',
    equipmentId: 'stage2c-equipment-chair',
    exerciseOneId: 'stage2c-exercise-chair-squat',
    exerciseTwoId: 'stage2c-exercise-wall-stretch',
    themeWeekId: 'stage2c-theme-chair-week',
};

export async function resetRuntimeE2EData(prisma: PrismaService, config: RuntimeE2EConfig) {
    await prisma.shareCard.deleteMany({ where: { userId: config.testUserId } });
    await prisma.sessionExercise.deleteMany({ where: { session: { userId: config.testUserId } } });
    await prisma.workoutSession.deleteMany({ where: { userId: config.testUserId } });
    await prisma.themeWeekParticipation.deleteMany({ where: { userId: config.testUserId } });
    await prisma.user.deleteMany({ where: { id: config.testUserId } });
    await prisma.exerciseEquipment.deleteMany({
        where: { exerciseId: { in: [runtimeE2EIds.exerciseOneId, runtimeE2EIds.exerciseTwoId] } },
    });
    await prisma.exerciseScenario.deleteMany({
        where: { exerciseId: { in: [runtimeE2EIds.exerciseOneId, runtimeE2EIds.exerciseTwoId] } },
    });
    await prisma.scenarioEquipment.deleteMany({ where: { scenarioId: runtimeE2EIds.scenarioId } });
    await prisma.exercise.deleteMany({
        where: { id: { in: [runtimeE2EIds.exerciseOneId, runtimeE2EIds.exerciseTwoId] } },
    });
    await prisma.equipment.deleteMany({ where: { id: runtimeE2EIds.equipmentId } });
    await prisma.scenario.deleteMany({ where: { id: runtimeE2EIds.scenarioId } });
    await prisma.themeWeek.deleteMany({ where: { id: runtimeE2EIds.themeWeekId } });
}

export async function seedRuntimeE2EData(prisma: PrismaService, config: RuntimeE2EConfig) {
    await resetRuntimeE2EData(prisma, config);

    await prisma.user.create({
        data: { id: config.testUserId, email: config.testUserEmail, name: 'Stage 2C Runtime User' },
    });
    await prisma.scenario.create({
        data: {
            id: runtimeE2EIds.scenarioId,
            code: 'stage2c_office',
            name: 'Stage 2C Office',
            noiseTolerance: 'QUIET',
            spaceRequirement: 'SMALL',
            iconUrl: '/test/stage2c-office.png',
        },
    });
    await prisma.equipment.create({
        data: {
            id: runtimeE2EIds.equipmentId,
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
        data: {
            scenarioId: runtimeE2EIds.scenarioId,
            equipmentId: runtimeE2EIds.equipmentId,
            isCommon: true,
        },
    });

    const description = {
        keyPoints: ['Controlled movement'],
        steps: ['Start', 'Move', 'Finish'],
        warnings: ['Stop if painful'],
    };
    for (const exercise of [
        {
            id: runtimeE2EIds.exerciseOneId,
            code: 'stage2c_chair_squat',
            name: 'Stage 2C Chair Squat',
            muscle: 'LEGS',
            intent: 'STRENGTH',
        },
        {
            id: runtimeE2EIds.exerciseTwoId,
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
                primaryMuscle: exercise.muscle as any,
                intentType: exercise.intent as any,
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
            data: { exerciseId: exercise.id, scenarioId: runtimeE2EIds.scenarioId },
        });
        await prisma.exerciseEquipment.create({
            data: {
                exerciseId: exercise.id,
                equipmentId: runtimeE2EIds.equipmentId,
                isRequired: false,
            },
        });
    }
}

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ExecutionContext } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { JwtAuthGuard } from '../../src/common/guards/jwt-auth.guard';
import { SupabaseApiService } from '../../src/common/services/supabase-api.service';
import {
    assertRuntimeE2ESafe,
    getRuntimeE2EConfig,
    RuntimeE2EConfig,
} from '../helpers/runtime-e2e-env.helper';
import {
    resetRuntimeE2EData,
    runtimeE2EIds,
    seedRuntimeE2EData,
} from '../helpers/runtime-e2e-seed.helper';

const runtimeConfig = getRuntimeE2EConfig();
const runtimeDescribe = runtimeConfig.enabled ? describe : describe.skip;

function createSupabaseApiMock(config: RuntimeE2EConfig) {
    const exerciseRows = [
        {
            id: runtimeE2EIds.exerciseOneId,
            code: 'stage2c_chair_squat',
            name: 'Stage 2C Chair Squat',
            primary_muscle: 'LEGS',
            intent_type: 'STRENGTH',
            difficulty: 'GREEN',
            default_duration: 30,
            default_sets: 1,
            duration_type: 'TIME',
            description: {
                keyPoints: ['Controlled movement'],
                steps: ['Start', 'Move', 'Finish'],
                warnings: ['Stop if painful'],
            },
            tags: ['stage2c'],
            is_active: true,
        },
        {
            id: runtimeE2EIds.exerciseTwoId,
            code: 'stage2c_wall_stretch',
            name: 'Stage 2C Wall Stretch',
            primary_muscle: 'FULL_BODY',
            intent_type: 'STRETCH',
            difficulty: 'GREEN',
            default_duration: 30,
            default_sets: 1,
            duration_type: 'TIME',
            description: {
                keyPoints: ['Gentle stretch'],
                steps: ['Reach', 'Hold'],
                warnings: ['Stop if painful'],
            },
            tags: ['stage2c'],
            is_active: true,
        },
    ];

    return {
        getById: jest.fn(async (table: string, id: string) => {
            if (table === 'users' && id === config.testUserId) {
                return {
                    id: config.testUserId,
                    email: config.testUserEmail,
                    name: 'Stage 2C Runtime User',
                    total_workouts: 0,
                    total_duration_sec: 0,
                    current_streak: 0,
                    longest_streak: 0,
                };
            }
            if (table === 'exercises') {
                return exerciseRows.find(exercise => exercise.id === id) || null;
            }
            return null;
        }),
        getByField: jest.fn(async (table: string) => {
            if (table === 'exercises') return exerciseRows;
            return [];
        }),
        get: jest.fn(async (table: string) => {
            if (table === 'exercises') return exerciseRows;
            if (table === 'scenarios') {
                return [
                    {
                        id: runtimeE2EIds.scenarioId,
                        code: 'stage2c_office',
                        name: 'Stage 2C Office',
                        is_active: true,
                    },
                ];
            }
            if (table === 'equipment') {
                return [
                    {
                        id: runtimeE2EIds.equipmentId,
                        code: 'stage2c_chair',
                        name: 'Stage 2C Chair',
                        category: 'FURNITURE',
                        is_active: true,
                    },
                ];
            }
            if (table === 'theme_weeks') return [];
            return [];
        }),
        post: jest.fn(async (_table: string, payload: Record<string, unknown>) => payload),
        patch: jest.fn(
            async (_table: string, _id: string, payload: Record<string, unknown>) => payload
        ),
    };
}

describe('Runtime E2E safety preflight', () => {
    it('is skipped safely unless SNAPREP_RUNTIME_E2E=1 is explicitly set', () => {
        if (runtimeConfig.enabled) {
            expect(runtimeConfig.enabled).toBe(true);
            return;
        }

        expect(runtimeConfig.enabled).toBe(false);
    });
});

runtimeDescribe('Stage 2C current-contract runtime E2E', () => {
    let app: INestApplication;
    let prisma: PrismaService;
    let config: RuntimeE2EConfig;
    let sessionId: string;
    let cardId: string;

    beforeAll(async () => {
        config = assertRuntimeE2ESafe({ destructive: true });
        process.env.DATABASE_URL = config.databaseUrl;
        process.env.DIRECT_URL = config.directUrl || config.databaseUrl;

        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        })
            .overrideGuard(JwtAuthGuard)
            .useValue({
                canActivate: (context: ExecutionContext) => {
                    const req = context.switchToHttp().getRequest();
                    req.user = { id: config.testUserId, email: config.testUserEmail };
                    return true;
                },
            })
            .overrideProvider(SupabaseApiService)
            .useValue(createSupabaseApiMock(config))
            .compile();

        app = moduleFixture.createNestApplication();
        await app.init();
        prisma = app.get<PrismaService>(PrismaService);
        await seedRuntimeE2EData(prisma, config);
    });

    afterAll(async () => {
        if (prisma && config?.allowReset) {
            await resetRuntimeE2EData(prisma, config);
        }
        if (app) await app.close();
    });

    it('catalog -> recommendation -> session -> card -> My/Profile current routes work', async () => {
        await request(app.getHttpServer())
            .get('/rest/v1/scenarios')
            .expect(response => {
                expect(response.status).toBeLessThan(500);
            });

        await request(app.getHttpServer())
            .get('/rest/v1/equipment')
            .expect(response => {
                expect(response.status).toBeLessThan(500);
            });

        const recommendation = await request(app.getHttpServer())
            .post('/api/v1/recommendations/quick')
            .send({
                userId: config.testUserId,
                intent: 'STRETCH',
                equipmentCodes: ['stage2c_chair'],
                scenarioCode: 'stage2c_office',
                targetMuscles: ['FULL_BODY'],
                duration: 60,
                difficulty: 'GREEN',
            })
            .expect(200);

        expect(
            recommendation.body.exercises?.length || recommendation.body.data?.exercises?.length
        ).toBeGreaterThan(0);

        const created = await request(app.getHttpServer())
            .post('/api/v1/workout-sessions')
            .set('Authorization', 'Bearer stage2c-test-token')
            .send({
                userId: config.testUserId,
                intentType: 'STRETCH',
                scenarioId: runtimeE2EIds.scenarioId,
                targetMuscles: ['FULL_BODY'],
                totalDuration: 60,
                difficulty: 'GREEN',
                exercises: [
                    {
                        exerciseId: runtimeE2EIds.exerciseTwoId,
                        sequenceOrder: 1,
                        duration: 30,
                        sets: 1,
                    },
                ],
            })
            .expect(201);

        sessionId = created.body.data.id;
        expect(sessionId).toMatch(/^c[a-z0-9]+$/);

        await request(app.getHttpServer())
            .get(`/api/v1/workout-sessions/${sessionId}`)
            .set('Authorization', 'Bearer stage2c-test-token')
            .expect(200);

        await request(app.getHttpServer())
            .patch(`/api/v1/workout-sessions/${sessionId}`)
            .set('Authorization', 'Bearer stage2c-test-token')
            .send({ status: 'IN_PROGRESS', currentStep: 1 })
            .expect(200);

        await request(app.getHttpServer())
            .post(`/api/v1/workout-sessions/${sessionId}/complete`)
            .set('Authorization', 'Bearer stage2c-test-token')
            .send({ actualDuration: 55, rating: 5, feedback: 'Stage 2C runtime complete' })
            .expect(201);

        const card = await request(app.getHttpServer())
            .post('/api/v1/cards/generate')
            .send({ sessionId, cardTemplate: 'classic', specialTags: ['stage2c'] })
            .expect(201);

        cardId = card.body.data.id;
        expect(cardId).toBeDefined();

        await request(app.getHttpServer()).get(`/api/v1/cards/${cardId}`).expect(200);
        await request(app.getHttpServer()).get(`/api/v1/cards/session/${sessionId}`).expect(200);
        await request(app.getHttpServer())
            .get(`/api/v1/users/${config.testUserId}/cards`)
            .expect(200);
        await request(app.getHttpServer())
            .get(`/api/v1/users/${config.testUserId}/sessions`)
            .set('Authorization', 'Bearer stage2c-test-token')
            .expect(200);
        await request(app.getHttpServer())
            .get(`/api/v1/users/${config.testUserId}/stats`)
            .set('Authorization', 'Bearer stage2c-test-token')
            .expect(200);
    });
});

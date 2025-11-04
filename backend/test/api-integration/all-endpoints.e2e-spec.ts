import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('API Integration Tests - All 29 Endpoints', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let httpServer: any;
  let userToken: string;
  let userId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);
    httpServer = app.getHttpServer();

    // 创建测试用户和token
    const authResponse = await request(httpServer)
      .post('/auth/anonymous')
      .expect(201);

    userToken = authResponse.body.accessToken;
    userId = authResponse.body.user.id;
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('Supabase Auto REST API (12 endpoints)', () => {
    describe('GET /rest/v1/scenarios', () => {
      it('should return all active scenarios', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/scenarios')
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBeGreaterThan(0);

        // 验证数据结构
        response.body.forEach(scenario => {
          expect(scenario).toHaveProperty('id');
          expect(scenario).toHaveProperty('code');
          expect(scenario).toHaveProperty('name');
          expect(scenario).toHaveProperty('description');
          expect(scenario).toHaveProperty('is_active');
          expect(scenario.is_active).toBe(true);
        });

        // 验证默认排序
        for (let i = 1; i < response.body.length; i++) {
          expect(response.body[i].display_order).toBeGreaterThanOrEqual(
            response.body[i - 1].display_order
          );
        }
      });

      it('should support filtering and ordering', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/scenarios')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            select: 'id,code,name',
            order: 'display_order.asc',
            is_active: 'eq.true',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        if (response.body.length > 0) {
          expect(response.body[0]).toHaveProperty('id');
          expect(response.body[0]).toHaveProperty('code');
          expect(response.body[0]).toHaveProperty('name');
          expect(response.body[0]).not.toHaveProperty('description');
        }
      });
    });

    describe('GET /rest/v1/equipment', () => {
      it('should return all active equipment', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBeGreaterThan(0);

        response.body.forEach(equipment => {
          expect(equipment).toHaveProperty('id');
          expect(equipment).toHaveProperty('code');
          expect(equipment).toHaveProperty('name');
          expect(equipment).toHaveProperty('category');
          expect(equipment).toHaveProperty('is_active');
          expect(equipment.is_active).toBe(true);
        });
      });

      it('should filter by category', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            category: 'eq.FURNITURE',
          })
          .expect(200);

        response.body.forEach(equipment => {
          expect(equipment.category).toBe('FURNITURE');
        });
      });
    });

    describe('GET /rest/v1/exercises', () => {
      it('should return active exercises with associations', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/exercises')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            select: '*,exercise_equipment(equipment(*))',
            is_active: 'eq.true',
            limit: 10,
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBeLessThanOrEqual(10);

        response.body.forEach(exercise => {
          expect(exercise).toHaveProperty('id');
          expect(exercise).toHaveProperty('code');
          expect(exercise).toHaveProperty('name');
          expect(exercise).toHaveProperty('intent_type');
          expect(exercise).toHaveProperty('difficulty');
          expect(exercise).toHaveProperty('primary_muscle');
          expect(exercise).toHaveProperty('exercise_equipment');
          expect(exercise.exercise_equipment).toBeInstanceOf(Array);
        });
      });

      it('should filter by intent type and difficulty', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/exercises')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            intent_type: 'eq.STRETCH',
            difficulty: 'eq.GREEN',
            is_active: 'eq.true',
          })
          .expect(200);

        response.body.forEach(exercise => {
          expect(exercise.intent_type).toBe('STRETCH');
          expect(exercise.difficulty).toBe('GREEN');
        });
      });
    });

    describe('GET /rest/v1/theme_weeks', () => {
      it('should return theme weeks with date filtering', async () => {
        const today = new Date().toISOString();

        const response = await request(httpServer)
          .get('/rest/v1/theme_weeks')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            start_date: `lte.${today}`,
            end_date: `gte.${today}`,
            is_active: 'eq.true',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(theme => {
          expect(theme).toHaveProperty('id');
          expect(theme).toHaveProperty('name');
          expect(theme).toHaveProperty('equipment_series');
          expect(theme).toHaveProperty('target_count');
          expect(new Date(theme.start_date)).toBeLessThanOrEqual(new Date());
          expect(new Date(theme.end_date)).toBeGreaterThanOrEqual(new Date());
        });
      });
    });

    describe('GET /rest/v1/workout_sessions', () => {
      let testSessionId: string;

      beforeEach(async () => {
        // 创建测试会话
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 60,
          })
          .expect(201);

        testSessionId = sessionResponse.body.sessionId;
      });

      it('should return user workout sessions', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/workout_sessions')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            order: 'created_at.desc',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(session => {
          expect(session).toHaveProperty('id');
          expect(session).toHaveProperty('user_id');
          expect(session).toHaveProperty('intent_type');
          expect(session).toHaveProperty('difficulty');
          expect(session).toHaveProperty('status');
          expect(session.user_id).toBe(userId);
        });
      });

      it('should filter by status and date range', async () => {
        const today = new Date().toISOString().split('T')[0];

        const response = await request(httpServer)
          .get('/rest/v1/workout_sessions')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            status: 'eq.COMPLETED',
            created_at: `gte.${today}`,
          })
          .expect(200);

        response.body.forEach(session => {
          expect(session.status).toBe('COMPLETED');
          expect(session.created_at.startsWith(today)).toBe(true);
        });
      });
    });

    describe('GET /rest/v1/session_exercises', () => {
      let testSessionId: string;

      beforeEach(async () => {
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRENGTH',
            difficulty: 'BLUE',
            equipmentCodes: ['chair'],
            targetMuscles: ['LEGS'],
            duration: 90,
          })
          .expect(201);

        testSessionId = sessionResponse.body.sessionId;
      });

      it('should return exercises for a session', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/session_exercises')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            session_id: `eq.${testSessionId}`,
            select: '*,exercise(*)',
            order: 'sequence_order.asc',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBe(3);

        response.body.forEach((sessionExercise, index) => {
          expect(sessionExercise).toHaveProperty('id');
          expect(sessionExercise).toHaveProperty('session_id');
          expect(sessionExercise).toHaveProperty('exercise_id');
          expect(sessionExercise).toHaveProperty('sequence_order');
          expect(sessionExercise).toHaveProperty('exercise');
          expect(sessionExercise.session_id).toBe(testSessionId);
          expect(sessionExercise.sequence_order).toBe(index + 1);
        });
      });
    });

    describe('GET /rest/v1/share_cards', () => {
      let testCardId: string;

      beforeEach(async () => {
        // 创建并完成训练，生成卡片
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'CARDIO',
            difficulty: 'BLUE',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 60,
          })
          .expect(201);

        const sessionId = sessionResponse.body.sessionId;

        // 完成训练
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        for (let i = 1; i <= 3; i++) {
          await request(httpServer)
            .post(`/api/v1/workout-sessions/${sessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({ exerciseSequence: i })
            .expect(200);
        }

        // 生成卡片
        const cardResponse = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: sessionId,
            style: 'classic',
          })
          .expect(201);

        testCardId = cardResponse.body.cardId;
      });

      it('should return user cards with session info', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/share_cards')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            select: '*,workout_session(*)',
            order: 'created_at.desc',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(card => {
          expect(card).toHaveProperty('id');
          expect(card).toHaveProperty('user_id');
          expect(card).toHaveProperty('session_id');
          expect(card).toHaveProperty('equipment_code');
          expect(card).toHaveProperty('rarity_level');
          expect(card).toHaveProperty('workout_session');
          expect(card.user_id).toBe(userId);
        });
      });

      it('should filter by rarity and equipment', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/share_cards')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            rarity_level: 'in.(COMMON,UNCOMMON)',
            equipment_code: 'eq.hands_free',
          })
          .expect(200);

        response.body.forEach(card => {
          expect(['COMMON', 'UNCOMMON']).toContain(card.rarity_level);
          expect(card.equipment_code).toBe('hands_free');
        });
      });
    });

    describe('GET /rest/v1/theme_week_participations', () => {
      it('should return user theme week participations', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/theme_week_participations')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            select: '*,theme_week(*)',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(participation => {
          expect(participation).toHaveProperty('id');
          expect(participation).toHaveProperty('user_id');
          expect(participation).toHaveProperty('theme_week_id');
          expect(participation).toHaveProperty('status');
          expect(participation).toHaveProperty('progress_percent');
          expect(participation).toHaveProperty('theme_week');
          expect(participation.user_id).toBe(userId);
        });
      });
    });

    describe('GET /rest/v1/users', () => {
      it('should return current user info', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/users')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            id: `eq.${userId}`,
            select: 'id,email,nickname,is_anonymous,streak_count,total_sessions',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBe(1);

        const user = response.body[0];
        expect(user).toHaveProperty('id');
        expect(user).toHaveProperty('is_anonymous');
        expect(user).toHaveProperty('streak_count');
        expect(user).toHaveProperty('total_sessions');
        expect(user.id).toBe(userId);
      });

      it('should not return other users data', async () => {
        // 创建另一个用户
        const otherUserResponse = await request(httpServer)
          .post('/auth/anonymous')
          .expect(201);

        const otherUserId = otherUserResponse.body.user.id;

        // 尝试访问其他用户数据
        const response = await request(httpServer)
          .get('/rest/v1/users')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            id: `eq.${otherUserId}`,
          })
          .expect(200);

        // 根据RLS策略，应该返回空数组或无权限
        expect(response.body).toBeInstanceOf(Array);
        expect(response.body.length).toBe(0);
      });
    });

    describe('GET /rest/v1/user_preferences', () => {
      beforeEach(async () => {
        // 创建一些用户偏好数据
        await prisma.userPreference.create({
          data: {
            userId: userId,
            equipmentCode: 'chair',
            intentType: 'STRETCH',
            preferenceScore: 8.5,
            usageCount: 10,
            lastUsed: new Date(),
          },
        });
      });

      it('should return user preferences', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/user_preferences')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            order: 'preference_score.desc',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(preference => {
          expect(preference).toHaveProperty('id');
          expect(preference).toHaveProperty('user_id');
          expect(preference).toHaveProperty('equipment_code');
          expect(preference).toHaveProperty('intent_type');
          expect(preference).toHaveProperty('preference_score');
          expect(preference.user_id).toBe(userId);
        });
      });
    });

    describe('GET /rest/v1/rarity_stats', () => {
      it('should return equipment rarity statistics', async () => {
        const response = await request(httpServer)
          .get('/rest/v1/rarity_stats')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            select: 'equipment_code,rarity_level,global_percentile',
            order: 'global_percentile.desc',
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(stat => {
          expect(stat).toHaveProperty('equipment_code');
          expect(stat).toHaveProperty('rarity_level');
          expect(stat).toHaveProperty('global_percentile');
          expect(['COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY']).toContain(
            stat.rarity_level
          );
          expect(stat.global_percentile).toBeGreaterThanOrEqual(0);
          expect(stat.global_percentile).toBeLessThanOrEqual(100);
        });
      });
    });

    describe('GET /rest/v1/daily_trainings', () => {
      beforeEach(async () => {
        // 创建每日训练统计
        await prisma.dailyTraining.create({
          data: {
            userId: userId,
            trainingDate: new Date(),
            sessionsCount: 2,
            totalDuration: 120,
            exercisesCompleted: 6,
            difficultyDistribution: { GREEN: 1, BLUE: 1, RED: 0 },
          },
        });
      });

      it('should return user daily training stats', async () => {
        const today = new Date().toISOString().split('T')[0];

        const response = await request(httpServer)
          .get('/rest/v1/daily_trainings')
          .set('Authorization', `Bearer ${userToken}`)
          .query({
            user_id: `eq.${userId}`,
            training_date: `gte.${today}`,
          })
          .expect(200);

        expect(response.body).toBeInstanceOf(Array);
        response.body.forEach(training => {
          expect(training).toHaveProperty('id');
          expect(training).toHaveProperty('user_id');
          expect(training).toHaveProperty('training_date');
          expect(training).toHaveProperty('sessions_count');
          expect(training).toHaveProperty('total_duration');
          expect(training).toHaveProperty('exercises_completed');
          expect(training.user_id).toBe(userId);
        });
      });
    });
  });

  describe('NestJS Custom API (14 endpoints)', () => {
    describe('POST /api/v1/recommendations/quick', () => {
      it('should generate quick workout recommendations', async () => {
        const response = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['NECK_SHOULDERS'],
            duration: 60,
          })
          .expect(201);

        expect(response.body.exercises).toBeInstanceOf(Array);
        expect(response.body.exercises.length).toBe(3);
        expect(response.body.sessionId).toBeDefined();
        expect(response.body.alternatives).toBeDefined();

        // 验证动作符合条件
        response.body.exercises.forEach(exercise => {
          expect(exercise.intentType).toBe('STRETCH');
          expect(exercise.difficulty).toBe('GREEN');
        });
      });

      it('should handle different intent and difficulty combinations', async () => {
        const testCases = [
          { intentType: 'RELAX', difficulty: 'GREEN' },
          { intentType: 'CARDIO', difficulty: 'BLUE' },
          { intentType: 'STRENGTH', difficulty: 'RED' },
        ];

        for (const testCase of testCases) {
          const response = await request(httpServer)
            .post('/api/v1/recommendations/quick')
            .set('Authorization', `Bearer ${userToken}`)
            .send({
              ...testCase,
              equipmentCodes: ['hands_free'],
              targetMuscles: ['FULL_BODY'],
              duration: 60,
            })
            .expect(201);

          expect(response.body.exercises.length).toBe(3);
          response.body.exercises.forEach(exercise => {
            expect(exercise.intentType).toBe(testCase.intentType);
            expect(exercise.difficulty).toBe(testCase.difficulty);
          });
        }
      });
    });

    describe('POST /api/v1/recommendations/scenario', () => {
      it('should generate scenario-based recommendations', async () => {
        const response = await request(httpServer)
          .post('/api/v1/recommendations/scenario')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            scenarioCode: 'office',
          })
          .expect(201);

        expect(response.body.exercises).toBeInstanceOf(Array);
        expect(response.body.exercises.length).toBe(3);
        expect(response.body.sessionId).toBeDefined();
        expect(response.body.scenarioInfo).toBeDefined();
        expect(response.body.scenarioInfo.code).toBe('office');

        // 验证动作适合办公室场景
        response.body.exercises.forEach(exercise => {
          const isOfficeAppropriate =
            exercise.tags.includes('chair') ||
            exercise.tags.includes('wall') ||
            exercise.tags.includes('silent') ||
            exercise.tags.includes('office');
          expect(isOfficeAppropriate).toBe(true);
        });
      });
    });

    describe('POST /api/v1/recommendations/with-equipment', () => {
      it('should generate equipment-specific recommendations', async () => {
        const response = await request(httpServer)
          .post('/api/v1/recommendations/with-equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            equipmentCodes: ['chair', 'wall'],
            intentType: 'STRETCH',
            difficulty: 'GREEN',
          })
          .expect(201);

        expect(response.body.exercises).toBeInstanceOf(Array);
        expect(response.body.exercises.length).toBe(3);
        expect(response.body.sessionId).toBeDefined();

        // 验证动作使用了指定器材
        response.body.exercises.forEach(exercise => {
          const usesSelectedEquipment =
            exercise.tags.includes('chair') || exercise.tags.includes('wall');
          expect(usesSelectedEquipment).toBe(true);
        });
      });
    });

    describe('POST /api/v1/ai/recognize-equipment', () => {
      it('should handle equipment recognition', async () => {
        const mockImageBuffer = Buffer.from('mock-image-data');

        const response = await request(httpServer)
          .post('/api/v1/ai/recognize-equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .attach('image', mockImageBuffer, 'test-image.jpg')
          .expect(200);

        expect(response.body.recognized).toBeInstanceOf(Array);
        expect(response.body.confidence).toBeDefined();
        expect(response.body.confidence).toBeGreaterThanOrEqual(0);
        expect(response.body.confidence).toBeLessThanOrEqual(1);

        if (response.body.confidence >= 0.85) {
          expect(response.body.autoPreselected).toBe(true);
          expect(response.body.preselectedEquipment).toBeDefined();
        } else {
          expect(response.body.candidates).toBeInstanceOf(Array);
        }
      });

      it('should handle permission denied scenario', async () => {
        const response = await request(httpServer)
          .post('/api/v1/ai/recognize-equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            permissionDenied: true,
          })
          .expect(200);

        expect(response.body.fallbackOptions).toBeDefined();
        expect(response.body.message).toContain('可手选继续');
      });
    });

    describe('POST /api/v1/workout-sessions/:sessionId/start', () => {
      let testSessionId: string;

      beforeEach(async () => {
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'CARDIO',
            difficulty: 'BLUE',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 90,
          })
          .expect(201);

        testSessionId = sessionResponse.body.sessionId;
      });

      it('should start workout session', async () => {
        const response = await request(httpServer)
          .post(`/api/v1/workout-sessions/${testSessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(response.body.workoutStarted).toBe(true);
        expect(response.body.currentExercise).toBeDefined();
        expect(response.body.progress).toBeDefined();

        // 验证数据库状态更新
        const session = await prisma.workoutSession.findUnique({
          where: { id: testSessionId },
        });

        expect(session.status).toBe('IN_PROGRESS');
        expect(session.startedAt).toBeDefined();
      });
    });

    describe('POST /api/v1/workout-sessions/:sessionId/complete-exercise', () => {
      let activeSessionId: string;

      beforeEach(async () => {
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRENGTH',
            difficulty: 'BLUE',
            equipmentCodes: ['chair'],
            targetMuscles: ['LEGS'],
            duration: 90,
          })
          .expect(201);

        activeSessionId = sessionResponse.body.sessionId;

        // 开始训练
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${activeSessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);
      });

      it('should complete individual exercises', async () => {
        // 完成第一个动作
        const response = await request(httpServer)
          .post(`/api/v1/workout-sessions/${activeSessionId}/complete-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            exerciseSequence: 1,
          })
          .expect(200);

        expect(response.body.progress.completed).toBe(1);
        expect(response.body.progress.total).toBe(3);
        expect(response.body.progress.percentage).toBeCloseTo(33.33, 1);
      });

      it('should complete full workout', async () => {
        // 完成所有动作
        for (let i = 1; i <= 3; i++) {
          const response = await request(httpServer)
            .post(`/api/v1/workout-sessions/${activeSessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({
              exerciseSequence: i,
            })
            .expect(200);

          if (i === 3) {
            expect(response.body.workoutCompleted).toBe(true);
            expect(response.body.progress.percentage).toBe(100);
          }
        }

        // 验证会话完成状态
        const session = await prisma.workoutSession.findUnique({
          where: { id: activeSessionId },
        });

        expect(session.status).toBe('COMPLETED');
        expect(session.completedAt).toBeDefined();
      });
    });

    describe('POST /api/v1/workout-sessions/:sessionId/replace-exercise', () => {
      let testSessionId: string;

      beforeEach(async () => {
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['wall'],
            targetMuscles: ['CHEST_BACK'],
            duration: 60,
          })
          .expect(201);

        testSessionId = sessionResponse.body.sessionId;
      });

      it('should replace exercise with alternative', async () => {
        // 获取替换选项
        const alternativesResponse = await request(httpServer)
          .get(`/api/v1/workout-sessions/${testSessionId}/exercise/1/alternatives`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        const newExerciseId = alternativesResponse.body.alternatives[0].id;

        // 执行替换
        const replaceResponse = await request(httpServer)
          .post(`/api/v1/workout-sessions/${testSessionId}/replace-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            position: 1,
            newExerciseId: newExerciseId,
          })
          .expect(200);

        expect(replaceResponse.body.replaced).toBe(true);
        expect(replaceResponse.body.newExercise.id).toBe(newExerciseId);

        // 验证数据库更新
        const sessionExercise = await prisma.sessionExercise.findFirst({
          where: {
            sessionId: testSessionId,
            sequenceOrder: 1,
          },
        });

        expect(sessionExercise.exerciseId).toBe(newExerciseId);
      });
    });

    describe('POST /api/v1/workout-sessions/:sessionId/regenerate', () => {
      let originalSessionId: string;

      beforeEach(async () => {
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'RELAX',
            difficulty: 'GREEN',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['NECK_SHOULDERS'],
            duration: 60,
          })
          .expect(201);

        originalSessionId = sessionResponse.body.sessionId;
      });

      it('should regenerate exercise set with same conditions', async () => {
        // 获取原始动作
        const originalResponse = await request(httpServer)
          .get(`/api/v1/workout-sessions/${originalSessionId}/result`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        const originalExerciseIds = originalResponse.body.exercises.map(ex => ex.id);

        // 换一批
        const newBatchResponse = await request(httpServer)
          .post(`/api/v1/workout-sessions/${originalSessionId}/regenerate`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(newBatchResponse.body.exercises.length).toBe(3);

        const newExerciseIds = newBatchResponse.body.exercises.map(ex => ex.id);

        // 验证与原动作无重复
        newExerciseIds.forEach(newId => {
          expect(originalExerciseIds).not.toContain(newId);
        });

        // 验证条件保持一致
        expect(newBatchResponse.body.sessionInfo.intentType).toBe('RELAX');
        expect(newBatchResponse.body.sessionInfo.difficulty).toBe('GREEN');
      });
    });

    describe('POST /api/v1/cards/generate', () => {
      let completedSessionId: string;

      beforeEach(async () => {
        // 创建并完成训练
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'CARDIO',
            difficulty: 'BLUE',
            equipmentCodes: ['chair'],
            targetMuscles: ['LEGS'],
            duration: 90,
          })
          .expect(201);

        completedSessionId = sessionResponse.body.sessionId;

        // 完成训练
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${completedSessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        for (let i = 1; i <= 3; i++) {
          await request(httpServer)
            .post(`/api/v1/workout-sessions/${completedSessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({ exerciseSequence: i })
            .expect(200);
        }
      });

      it('should generate share card within 800ms', async () => {
        const startTime = Date.now();

        const response = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: completedSessionId,
            style: 'classic',
          })
          .expect(201);

        const duration = Date.now() - startTime;
        expect(duration).toBeLessThan(800);

        expect(response.body.cardId).toBeDefined();
        expect(response.body.cardImageUrl).toBeDefined();
        expect(response.body.deepLink).toBeDefined();
        expect(response.body.rarity).toBeDefined();

        // 验证数据库记录
        const card = await prisma.shareCard.findUnique({
          where: { id: response.body.cardId },
        });

        expect(card).toBeDefined();
        expect(card.userId).toBe(userId);
        expect(card.sessionId).toBe(completedSessionId);
      });
    });

    describe('GET /api/v1/theme-weeks/current', () => {
      it('should return current active theme week', async () => {
        const response = await request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .expect(200);

        if (response.body) {
          expect(response.body.id).toBeDefined();
          expect(response.body.name).toBeDefined();
          expect(response.body.equipmentSeries).toBeDefined();
          expect(response.body.targetCount).toBeGreaterThan(0);
          expect(response.body.isActive).toBe(true);
          expect(response.body.remainingDays).toBeDefined();
          expect(response.body.globalStats).toBeDefined();
        }
      });
    });

    describe('POST /api/v1/theme-weeks/:themeWeekId/join', () => {
      let activeThemeWeekId: string;

      beforeEach(async () => {
        const themeWeekResponse = await request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .expect(200);

        if (themeWeekResponse.body) {
          activeThemeWeekId = themeWeekResponse.body.id;
        }
      });

      it('should join theme week challenge', async () => {
        if (!activeThemeWeekId) {
          expect(true).toBe(true); // Skip if no active theme week
          return;
        }

        const response = await request(httpServer)
          .post(`/api/v1/theme-weeks/${activeThemeWeekId}/join`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(201);

        expect(response.body.joined).toBe(true);
        expect(response.body.participationId).toBeDefined();
        expect(response.body.themeWeek).toBeDefined();

        // 验证数据库记录
        const participation = await prisma.themeWeekParticipation.findFirst({
          where: {
            userId: userId,
            themeWeekId: activeThemeWeekId,
          },
        });

        expect(participation).toBeDefined();
        expect(participation.status).toBe('ACTIVE');
      });

      it('should prevent duplicate participation', async () => {
        if (!activeThemeWeekId) {
          expect(true).toBe(true);
          return;
        }

        // 第一次加入
        await request(httpServer)
          .post(`/api/v1/theme-weeks/${activeThemeWeekId}/join`)
          .set('Authorization', `Bearer ${userToken}`)
          .catch(() => {}); // 可能已经加入

        // 第二次加入应该返回409
        const duplicateResponse = await request(httpServer)
          .post(`/api/v1/theme-weeks/${activeThemeWeekId}/join`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(409);

        expect(duplicateResponse.body.error).toContain('已经参与');
      });
    });

    describe('POST /api/v1/workouts/copy-from-deeplink', () => {
      let originalSessionId: string;
      let deepLink: string;

      beforeEach(async () => {
        // 创建原始训练并生成卡片
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['wall'],
            targetMuscles: ['CHEST_BACK'],
            duration: 60,
          })
          .expect(201);

        originalSessionId = sessionResponse.body.sessionId;

        // 完成训练
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${originalSessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        for (let i = 1; i <= 3; i++) {
          await request(httpServer)
            .post(`/api/v1/workout-sessions/${originalSessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({ exerciseSequence: i })
            .expect(200);
        }

        // 生成卡片
        const cardResponse = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: originalSessionId,
            style: 'classic',
          })
          .expect(201);

        deepLink = cardResponse.body.deepLink;
      });

      it('should copy workout from deeplink', async () => {
        // 创建新用户
        const newUserResponse = await request(httpServer)
          .post('/auth/anonymous')
          .expect(201);

        const newUserToken = newUserResponse.body.accessToken;

        // 复制训练
        const copyResponse = await request(httpServer)
          .post('/api/v1/workouts/copy-from-deeplink')
          .set('Authorization', `Bearer ${newUserToken}`)
          .send({
            deepLink: deepLink,
          })
          .expect(201);

        expect(copyResponse.body.newSessionId).toBeDefined();
        expect(copyResponse.body.exercises.length).toBe(3);

        // 验证使用相同条件
        const newSession = await prisma.workoutSession.findUnique({
          where: { id: copyResponse.body.newSessionId },
        });

        const originalSession = await prisma.workoutSession.findUnique({
          where: { id: originalSessionId },
        });

        expect(newSession.intentType).toBe(originalSession.intentType);
        expect(newSession.difficulty).toBe(originalSession.difficulty);
      });
    });
  });

  describe('Performance and Error Handling', () => {
    it('should handle concurrent API requests', async () => {
      const concurrentRequests = Array(10).fill(0).map(() =>
        request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 60,
          })
      );

      const responses = await Promise.all(concurrentRequests);

      responses.forEach(response => {
        expect(response.status).toBe(201);
        expect(response.body.exercises.length).toBe(3);
        expect(response.body.sessionId).toBeDefined();
      });

      // 验证生成的会话都是独立的
      const sessionIds = responses.map(r => r.body.sessionId);
      const uniqueSessionIds = [...new Set(sessionIds)];
      expect(uniqueSessionIds.length).toBe(sessionIds.length);
    });

    it('should handle invalid parameters gracefully', async () => {
      // 测试无效的意图类型
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: 'INVALID_INTENT',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(400);

      // 测试无效的器材代码
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['NONEXISTENT_EQUIPMENT'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(400);
    });

    it('should require authentication for protected endpoints', async () => {
      // 测试无token访问
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(401);

      // 测试无效token
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', 'Bearer invalid-token')
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(401);
    });
  });

  describe('Supabase Auth (2 flows)', () => {
    describe('Anonymous Authentication', () => {
      it('should create anonymous user and return tokens', async () => {
        const response = await request(httpServer)
          .post('/auth/anonymous')
          .expect(201);

        expect(response.body.user).toBeDefined();
        expect(response.body.user.isAnonymous).toBe(true);
        expect(response.body.accessToken).toBeDefined();
        expect(response.body.refreshToken).toBeDefined();
        expect(response.body.expiresIn).toBeDefined();

        // 验证token可用性
        const testResponse = await request(httpServer)
          .get('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${response.body.accessToken}`)
          .expect(200);
      });
    });

    describe('Email Authentication', () => {
      it('should send magic link for email signup', async () => {
        const testEmail = 'api-test@snaprep.com';

        const response = await request(httpServer)
          .post('/auth/signup-with-email')
          .send({
            email: testEmail,
          })
          .expect(201);

        expect(response.body.message).toContain('Magic link sent');
        expect(response.body.email).toBe(testEmail);
      });

      it('should upgrade anonymous account to email account', async () => {
        // 创建匿名用户
        const anonResponse = await request(httpServer)
          .post('/auth/anonymous')
          .expect(201);

        const anonUserId = anonResponse.body.user.id;
        const testEmail = 'upgrade-api-test@snaprep.com';

        // 升级为邮箱账户
        const upgradeResponse = await request(httpServer)
          .post('/auth/verify-magic-link')
          .send({
            token: 'mock-magic-link-token',
            email: testEmail,
            anonymousUserId: anonUserId,
          })
          .expect(200);

        expect(upgradeResponse.body.user.email).toBe(testEmail);
        expect(upgradeResponse.body.user.isAnonymous).toBe(false);
        expect(upgradeResponse.body.user.id).toBe(anonUserId);

        // 验证账户升级
        const user = await prisma.user.findUnique({
          where: { id: anonUserId },
        });

        expect(user.email).toBe(testEmail);
        expect(user.isAnonymous).toBe(false);
      });
    });
  });

  describe('Supabase Storage (1 endpoint)', () => {
    describe('POST /storage/v1/object/cards/:cardId', () => {
      it('should upload card image to storage', async () => {
        // 创建测试卡片
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 60,
          })
          .expect(201);

        const sessionId = sessionResponse.body.sessionId;

        // 完成训练
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        for (let i = 1; i <= 3; i++) {
          await request(httpServer)
            .post(`/api/v1/workout-sessions/${sessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({ exerciseSequence: i })
            .expect(200);
        }

        // 生成卡片
        const cardResponse = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: sessionId,
            style: 'classic',
          })
          .expect(201);

        const cardId = cardResponse.body.cardId;

        // 模拟上传卡片图片
        const mockImageBuffer = Buffer.from('mock-card-image-data');

        const uploadResponse = await request(httpServer)
          .post(`/storage/v1/object/cards/${cardId}`)
          .set('Authorization', `Bearer ${userToken}`)
          .attach('file', mockImageBuffer, 'card.png')
          .expect(200);

        expect(uploadResponse.body.Key).toBeDefined();
        expect(uploadResponse.body.url).toBeDefined();
        expect(uploadResponse.body.url).toContain(cardId);
      });

      it('should handle large file uploads', async () => {
        // 模拟较大的图片文件 (但仍在限制内)
        const largeImageBuffer = Buffer.alloc(1024 * 1024); // 1MB

        const cardResponse = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: 'mock-session-id',
            style: 'classic',
          })
          .catch(() => ({ body: { cardId: 'mock-card-id' } }));

        const uploadResponse = await request(httpServer)
          .post(`/storage/v1/object/cards/mock-card-id`)
          .set('Authorization', `Bearer ${userToken}`)
          .attach('file', largeImageBuffer, 'large-card.png')
          .expect(200);

        expect(uploadResponse.body.Key).toBeDefined();
      });

      it('should reject oversized files', async () => {
        // 模拟超大文件 (超过限制)
        const oversizedBuffer = Buffer.alloc(5 * 1024 * 1024); // 5MB

        await request(httpServer)
          .post('/storage/v1/object/cards/test-card-id')
          .set('Authorization', `Bearer ${userToken}`)
          .attach('file', oversizedBuffer, 'oversized.png')
          .expect(413); // Payload Too Large
      });
    });
  });
});
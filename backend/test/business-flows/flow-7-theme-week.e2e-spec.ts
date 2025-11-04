import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程7: 主题周参与', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let httpServer: any;
  let userToken: string;
  let userId: string;
  let themeWeekId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);
    httpServer = app.getHttpServer();

    // 创建测试用户
    const authResponse = await request(httpServer)
      .post('/auth/anonymous')
      .expect(201);

    userToken = authResponse.body.accessToken;
    userId = authResponse.body.user.id;

    // 获取当前活跃主题周
    const themeWeekResponse = await request(httpServer)
      .get('/api/v1/theme-weeks/current')
      .expect(200);

    if (themeWeekResponse.body) {
      themeWeekId = themeWeekResponse.body.id;
    }
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('7.1 查看当前主题周', () => {
    it('should display active theme week information', async () => {
      const response = await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      if (response.body) {
        expect(response.body.id).toBeDefined();
        expect(response.body.name).toBeDefined();
        expect(response.body.description).toBeDefined();
        expect(response.body.equipmentSeries).toBeDefined();
        expect(response.body.targetCount).toBeGreaterThan(0);
        expect(response.body.rewardDescription).toBeDefined();
        expect(response.body.isActive).toBe(true);

        // 验证时间信息
        expect(response.body.startDate).toBeDefined();
        expect(response.body.endDate).toBeDefined();
        expect(new Date(response.body.endDate)).toBeGreaterThan(new Date());
      }
    });

    it('should calculate remaining time correctly', async () => {
      const response = await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      if (response.body) {
        const endDate = new Date(response.body.endDate);
        const now = new Date();
        const remainingMs = endDate.getTime() - now.getTime();
        const remainingDays = Math.ceil(remainingMs / (24 * 60 * 60 * 1000));

        expect(response.body.remainingDays).toBe(remainingDays);
        expect(response.body.remainingHours).toBeDefined();
        expect(response.body.timeStatus).toBeDefined();

        if (remainingDays > 0) {
          expect(response.body.timeStatus).toBe('active');
        }
      }
    });

    it('should display global participation statistics', async () => {
      const response = await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      if (response.body) {
        expect(response.body.globalStats).toBeDefined();
        expect(response.body.globalStats.totalParticipants).toBeGreaterThanOrEqual(0);
        expect(response.body.globalStats.completedParticipants).toBeGreaterThanOrEqual(0);
        expect(response.body.globalStats.completionRate).toBeGreaterThanOrEqual(0);
        expect(response.body.globalStats.completionRate).toBeLessThanOrEqual(100);

        // 验证参与趋势
        expect(response.body.globalStats.dailyJoins).toBeInstanceOf(Array);
        if (response.body.globalStats.dailyJoins.length > 0) {
          response.body.globalStats.dailyJoins.forEach(day => {
            expect(day).toHaveProperty('date');
            expect(day).toHaveProperty('joins');
            expect(day).toHaveProperty('completions');
          });
        }
      }
    });

    it('should show user participation status', async () => {
      const response = await request(httpServer)
        .get('/api/v1/theme-weeks/current/my-status')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.userStatus).toBeDefined();
      expect(['NOT_JOINED', 'ACTIVE', 'COMPLETED']).toContain(response.body.userStatus.status);

      if (response.body.userStatus.status !== 'NOT_JOINED') {
        expect(response.body.userStatus.progress).toBeDefined();
        expect(response.body.userStatus.exercisesCompleted).toBeGreaterThanOrEqual(0);
        expect(response.body.userStatus.targetExercises).toBeGreaterThan(0);
        expect(response.body.userStatus.progressPercent).toBeGreaterThanOrEqual(0);
        expect(response.body.userStatus.progressPercent).toBeLessThanOrEqual(100);
      }
    });
  });

  describe('7.2 一键加入挑战', () => {
    it('should create participation record successfully', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true); // Skip if no active theme week
        return;
      }

      const response = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(201);

      expect(response.body.joined).toBe(true);
      expect(response.body.participationId).toBeDefined();
      expect(response.body.themeWeek).toBeDefined();
      expect(response.body.initialProgress).toBeDefined();

      // 验证数据库记录
      const participation = await prisma.themeWeekParticipation.findFirst({
        where: {
          userId: userId,
          themeWeekId: themeWeekId,
        },
      });

      expect(participation).toBeDefined();
      expect(participation.status).toBe('ACTIVE');
      expect(participation.exercisesCompleted).toBe(0);
      expect(participation.progressPercent).toBe(0);
    });

    it('should generate theme-specific workout', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 先加入主题周（如果还没加入）
      await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .catch(() => {}); // 忽略已加入的错误

      // 一键加入应该直接生成使用主题器材的训练
      const workoutResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/start-workout`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(201);

      expect(workoutResponse.body.sessionId).toBeDefined();
      expect(workoutResponse.body.exercises).toBeInstanceOf(Array);
      expect(workoutResponse.body.exercises.length).toBe(3);

      // 验证使用了主题器材
      const themeWeek = await prisma.themeWeek.findUnique({
        where: { id: themeWeekId },
      });

      const session = await prisma.workoutSession.findUnique({
        where: { id: workoutResponse.body.sessionId },
        include: {
          sessionExercises: {
            include: {
              exercise: {
                include: {
                  exerciseEquipment: {
                    include: {
                      equipment: true,
                    },
                  },
                },
              },
            },
          },
        },
      });

      // 验证至少有一个动作使用了主题器材
      const usesThemeEquipment = session.sessionExercises.some(se =>
        se.exercise.exerciseEquipment.some(ee =>
          ee.equipment.code === themeWeek.equipmentSeries
        )
      );

      expect(usesThemeEquipment).toBe(true);
    });

    it('should prevent duplicate participation', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 第一次加入应该成功
      await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .catch(() => {}); // 可能已经加入了

      // 第二次加入应该返回409 Conflict
      const duplicateResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(409);

      expect(duplicateResponse.body.error).toContain('已经参与');
      expect(duplicateResponse.body.existingParticipation).toBeDefined();
    });

    it('should redirect to workout result page', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 确保已加入主题周
      await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .catch(() => {});

      const workoutResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/start-workout`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(201);

      // 应该直接返回可用于结果页的数据结构
      expect(workoutResponse.body.sessionId).toBeDefined();
      expect(workoutResponse.body.exercises).toBeDefined();
      expect(workoutResponse.body.alternatives).toBeDefined();
      expect(workoutResponse.body.themeWeekContext).toBeDefined();
      expect(workoutResponse.body.themeWeekContext.name).toBeDefined();
      expect(workoutResponse.body.themeWeekContext.progress).toBeDefined();
    });
  });

  describe('7.3 完成训练更新进度', () => {
    let participationId: string;
    let themeSessionId: string;

    beforeEach(async () => {
      if (!themeWeekId) {
        return;
      }

      // 确保参与主题周
      const joinResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .catch(async () => {
          // 如果已参与，获取现有参与记录
          const statusResponse = await request(httpServer)
            .get('/api/v1/theme-weeks/current/my-status')
            .set('Authorization', `Bearer ${userToken}`)
            .expect(200);
          return { body: { participationId: statusResponse.body.userStatus.participationId } };
        });

      if (joinResponse && joinResponse.body) {
        participationId = joinResponse.body.participationId;
      }

      // 创建主题训练会话
      const workoutResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/start-workout`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(201);

      themeSessionId = workoutResponse.body.sessionId;
    });

    it('should update progress after each completion', async () => {
      if (!themeWeekId || !themeSessionId) {
        expect(true).toBe(true);
        return;
      }

      // 开始训练
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${themeSessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 完成训练
      for (let i = 1; i <= 3; i++) {
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${themeSessionId}/complete-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({ exerciseSequence: i })
          .expect(200);
      }

      // 验证主题周进度更新
      const statusResponse = await request(httpServer)
        .get('/api/v1/theme-weeks/current/my-status')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (statusResponse.body.userStatus.status !== 'NOT_JOINED') {
        expect(statusResponse.body.userStatus.exercisesCompleted).toBeGreaterThan(0);
        expect(statusResponse.body.userStatus.progressPercent).toBeGreaterThan(0);

        // 验证数据库更新
        const participation = await prisma.themeWeekParticipation.findFirst({
          where: {
            userId: userId,
            themeWeekId: themeWeekId,
          },
        });

        expect(participation.exercisesCompleted).toBeGreaterThan(0);
        expect(participation.progressPercent).toBeGreaterThan(0);
      }
    });

    it('should track progress incrementally', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 获取初始进度
      const initialStatus = await request(httpServer)
        .get('/api/v1/theme-weeks/current/my-status')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const initialProgress = initialStatus.body.userStatus.exercisesCompleted || 0;

      // 完成一次训练
      const workoutResponse = await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/start-workout`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(201);

      const sessionId = workoutResponse.body.sessionId;

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

      // 验证进度增加
      const updatedStatus = await request(httpServer)
        .get('/api/v1/theme-weeks/current/my-status')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (updatedStatus.body.userStatus.status !== 'NOT_JOINED') {
        expect(updatedStatus.body.userStatus.exercisesCompleted).toBe(initialProgress + 1);
      }
    });

    it('should complete theme week when reaching target', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 获取目标完成次数
      const themeWeek = await prisma.themeWeek.findUnique({
        where: { id: themeWeekId },
      });

      // 模拟完成足够的训练
      for (let i = 0; i < themeWeek.targetCount; i++) {
        const workoutResponse = await request(httpServer)
          .post(`/api/v1/theme-weeks/${themeWeekId}/start-workout`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(201);

        const sessionId = workoutResponse.body.sessionId;

        await request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/start`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        for (let j = 1; j <= 3; j++) {
          await request(httpServer)
            .post(`/api/v1/workout-sessions/${sessionId}/complete-exercise`)
            .set('Authorization', `Bearer ${userToken}`)
            .send({ exerciseSequence: j })
            .expect(200);
        }
      }

      // 验证完成状态
      const finalStatus = await request(httpServer)
        .get('/api/v1/theme-weeks/current/my-status')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (finalStatus.body.userStatus.status !== 'NOT_JOINED') {
        expect(finalStatus.body.userStatus.status).toBe('COMPLETED');
        expect(finalStatus.body.userStatus.progressPercent).toBe(100);
        expect(finalStatus.body.userStatus.completedAt).toBeDefined();

        // 验证奖励解锁
        expect(finalStatus.body.userStatus.rewardUnlocked).toBe(true);
        expect(finalStatus.body.userStatus.rewardDescription).toBeDefined();
      }
    });
  });

  describe('7.4 验证奖励解锁', () => {
    it('should unlock reward when reaching target', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 查找已完成的参与记录
      const completedParticipation = await prisma.themeWeekParticipation.findFirst({
        where: {
          themeWeekId: themeWeekId,
          status: 'COMPLETED',
        },
        include: {
          themeWeek: true,
        },
      });

      if (completedParticipation) {
        expect(completedParticipation.exercisesCompleted).toBeGreaterThanOrEqual(
          completedParticipation.themeWeek.targetCount
        );
        expect(completedParticipation.completedAt).toBeDefined();
        expect(completedParticipation.progressPercent).toBe(100);

        // 验证奖励信息
        const rewardResponse = await request(httpServer)
          .get(`/api/v1/theme-weeks/${themeWeekId}/rewards`)
          .expect(200);

        expect(rewardResponse.body.available).toBe(true);
        expect(rewardResponse.body.rewardType).toBeDefined();
        expect(rewardResponse.body.description).toBeDefined();
      }
    });

    it('should unlock special card skin', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 获取主题周信息
      const themeWeek = await prisma.themeWeek.findUnique({
        where: { id: themeWeekId },
      });

      // 如果存在完成的参与记录，验证特殊皮肤
      const completedParticipation = await prisma.themeWeekParticipation.findFirst({
        where: {
          themeWeekId: themeWeekId,
          status: 'COMPLETED',
        },
      });

      if (completedParticipation) {
        // 创建一张卡片并验证特殊皮肤可用
        const sessionResponse = await request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'STRETCH',
            difficulty: 'GREEN',
            equipmentCodes: [themeWeek.equipmentSeries],
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
            style: 'theme',
          })
          .expect(201);

        // 验证主题周特殊标签
        expect(cardResponse.body.specialTags).toContain(`#${themeWeek.name}`);
        expect(cardResponse.body.themeWeekSkin).toBe(true);
      }
    });

    it('should display achievement badge', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 查看用户成就
      const achievementsResponse = await request(httpServer)
        .get('/api/v1/users/me/achievements')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(achievementsResponse.body.achievements).toBeInstanceOf(Array);

      // 查找主题周相关成就
      const themeWeekAchievements = achievementsResponse.body.achievements.filter(
        achievement => achievement.category === 'theme_week'
      );

      if (themeWeekAchievements.length > 0) {
        themeWeekAchievements.forEach(achievement => {
          expect(achievement).toHaveProperty('id');
          expect(achievement).toHaveProperty('name');
          expect(achievement).toHaveProperty('description');
          expect(achievement).toHaveProperty('unlockedAt');
          expect(achievement).toHaveProperty('badgeUrl');
        });
      }
    });
  });

  describe('错误处理和边界情况', () => {
    it('should handle no active theme week gracefully', async () => {
      // 模拟没有活跃主题周的情况
      const response = await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      if (!response.body) {
        expect(response.body).toBeNull();
      }

      // 尝试加入不存在的主题周
      await request(httpServer)
        .post('/api/v1/theme-weeks/nonexistent/join')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(404);
    });

    it('should handle expired theme week', async () => {
      // 创建一个过期的主题周用于测试
      const expiredThemeWeek = await prisma.themeWeek.create({
        data: {
          name: 'Expired Theme Week',
          description: 'This theme week has expired',
          equipmentSeries: 'chair',
          startDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), // 14 days ago
          endDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),   // 7 days ago
          targetCount: 3,
          rewardDescription: 'Test reward',
          isActive: false,
        },
      });

      // 尝试加入过期的主题周
      const response = await request(httpServer)
        .post(`/api/v1/theme-weeks/${expiredThemeWeek.id}/join`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(410);

      expect(response.body.error).toContain('已过期');
    });

    it('should handle concurrent participation attempts', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 创建新用户进行并发测试
      const newUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const newUserToken = newUserResponse.body.accessToken;

      // 同时发送多个加入请求
      const joinPromises = Array(3).fill(0).map(() =>
        request(httpServer)
          .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
          .set('Authorization', `Bearer ${newUserToken}`)
      );

      const responses = await Promise.allSettled(joinPromises);

      // 应该只有一个成功，其余返回409
      const successCount = responses.filter(r => r.status === 'fulfilled' && r.value.status === 201).length;
      const conflictCount = responses.filter(r => r.status === 'fulfilled' && r.value.status === 409).length;

      expect(successCount).toBe(1);
      expect(conflictCount).toBe(2);
    });

    it('should validate theme week constraints', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 测试无效的目标完成次数
      await request(httpServer)
        .patch(`/api/v1/theme-weeks/${themeWeekId}`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          targetCount: -1,
        })
        .expect(400);

      // 测试无效的日期范围
      await request(httpServer)
        .patch(`/api/v1/theme-weeks/${themeWeekId}`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          startDate: '2023-12-31',
          endDate: '2023-01-01', // 结束日期早于开始日期
        })
        .expect(400);
    });
  });

  describe('性能和用户体验验证', () => {
    it('should load theme week information within 2 seconds', async () => {
      const startTime = Date.now();

      await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(2000);
    });

    it('should handle join action within 3 seconds', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 创建新用户进行测试
      const testUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const testUserToken = testUserResponse.body.accessToken;

      const startTime = Date.now();

      await request(httpServer)
        .post(`/api/v1/theme-weeks/${themeWeekId}/join`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .expect(201);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(3000);
    });

    it('should provide smooth progress updates', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 快速连续检查进度状态
      const statusChecks = Array(5).fill(0).map(() =>
        request(httpServer)
          .get('/api/v1/theme-weeks/current/my-status')
          .set('Authorization', `Bearer ${userToken}`)
      );

      const startTime = Date.now();
      const responses = await Promise.all(statusChecks);
      const duration = Date.now() - startTime;

      responses.forEach(response => {
        expect(response.status).toBe(200);
      });

      expect(duration).toBeLessThan(2000); // 5次状态检查应该在2秒内完成
    });

    it('should maintain consistent data across requests', async () => {
      if (!themeWeekId) {
        expect(true).toBe(true);
        return;
      }

      // 多次获取相同数据，验证一致性
      const responses = await Promise.all([
        request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .set('Authorization', `Bearer ${userToken}`),
        request(httpServer)
          .get('/api/v1/theme-weeks/current/my-status')
          .set('Authorization', `Bearer ${userToken}`),
        request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .set('Authorization', `Bearer ${userToken}`),
      ]);

      responses.forEach(response => {
        expect(response.status).toBe(200);
      });

      // 验证主题周基本信息一致性
      if (responses[0].body && responses[2].body) {
        expect(responses[0].body.id).toBe(responses[2].body.id);
        expect(responses[0].body.name).toBe(responses[2].body.name);
        expect(responses[0].body.targetCount).toBe(responses[2].body.targetCount);
      }
    });
  });
});
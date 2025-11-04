import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程6: 我的页面', () => {
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

    // 创建测试用户
    const authResponse = await request(httpServer)
      .post('/auth/anonymous')
      .expect(201);

    userToken = authResponse.body.accessToken;
    userId = authResponse.body.user.id;

    // 创建一些测试数据
    await createTestDataForUser(userId);
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  async function createTestDataForUser(userId: string) {
    // 创建一些历史训练会话
    for (let i = 0; i < 5; i++) {
      const sessionResponse = await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: i % 2 === 0 ? 'STRETCH' : 'CARDIO',
          difficulty: 'GREEN',
          equipmentCodes: ['chair', 'hands_free'][i % 2],
          targetMuscles: ['NECK_SHOULDERS', 'CORE'][i % 2],
          duration: 60,
        })
        .expect(201);

      const sessionId = sessionResponse.body.sessionId;

      // 完成训练
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

      // 生成卡片
      await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: sessionId,
          style: 'classic',
        })
        .expect(201);
    }
  }

  describe('6.1 页面结构与Header', () => {
    it('should display header with user info', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/profile')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.user).toBeDefined();
      expect(response.body.user.id).toBe(userId);
      expect(response.body.user.nickname).toBeDefined();

      // 验证统计信息
      expect(response.body.stats).toBeDefined();
      expect(response.body.stats.streakCount).toBeGreaterThanOrEqual(0);
      expect(response.body.stats.totalCards).toBeGreaterThanOrEqual(0);
      expect(response.body.stats.weeklyMinutes).toBeGreaterThanOrEqual(0);
    });

    it('should display 3 main tab navigation', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/navigation')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.tabs).toBeInstanceOf(Array);
      expect(response.body.tabs.length).toBe(3);

      const tabNames = response.body.tabs.map(tab => tab.name);
      expect(tabNames).toContain('cards');
      expect(tabNames).toContain('history');
      expect(tabNames).toContain('settings');

      // 验证每个tab的配置
      response.body.tabs.forEach(tab => {
        expect(tab).toHaveProperty('name');
        expect(tab).toHaveProperty('label');
        expect(tab).toHaveProperty('icon');
        expect(tab).toHaveProperty('badge');
      });
    });

    it('should display personal statistics correctly', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/stats')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const stats = response.body;

      // 验证连击统计
      expect(stats.streak).toBeDefined();
      expect(stats.streak.current).toBeGreaterThanOrEqual(0);
      expect(stats.streak.longest).toBeGreaterThanOrEqual(stats.streak.current);

      // 验证收集统计
      expect(stats.collection).toBeDefined();
      expect(stats.collection.totalCards).toBeGreaterThanOrEqual(0);
      expect(stats.collection.rareCards).toBeGreaterThanOrEqual(0);
      expect(stats.collection.rarityDistribution).toBeDefined();

      // 验证时长统计
      expect(stats.time).toBeDefined();
      expect(stats.time.thisWeek).toBeGreaterThanOrEqual(0);
      expect(stats.time.thisMonth).toBeGreaterThanOrEqual(0);
      expect(stats.time.total).toBeGreaterThanOrEqual(stats.time.thisWeek);
    });
  });

  describe('6.2 卡片收集Tab', () => {
    it('should display card collection with filters', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.cards).toBeInstanceOf(Array);
      expect(response.body.filters).toBeDefined();
      expect(response.body.pagination).toBeDefined();

      // 验证筛选器配置
      const filters = response.body.filters;
      expect(filters.rarity).toBeInstanceOf(Array);
      expect(filters.series).toBeInstanceOf(Array);
      expect(filters.rarity).toContain('All');
      expect(filters.rarity).toContain('COMMON');
      expect(filters.rarity).toContain('RARE');

      // 验证卡片数据结构
      if (response.body.cards.length > 0) {
        const card = response.body.cards[0];
        expect(card).toHaveProperty('id');
        expect(card).toHaveProperty('cardImageUrl');
        expect(card).toHaveProperty('rarity');
        expect(card).toHaveProperty('equipmentSeries');
        expect(card).toHaveProperty('createdAt');
      }
    });

    it('should filter cards by rarity', async () => {
      // 测试稀有度筛选
      const rarityResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ rarity: 'COMMON' })
        .expect(200);

      if (rarityResponse.body.cards.length > 0) {
        rarityResponse.body.cards.forEach(card => {
          expect(card.rarity).toBe('COMMON');
        });
      }

      // 测试全部筛选
      const allResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ rarity: 'All' })
        .expect(200);

      expect(allResponse.body.cards).toBeInstanceOf(Array);
    });

    it('should filter cards by equipment series', async () => {
      const seriesResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ series: '家具系' })
        .expect(200);

      if (seriesResponse.body.cards.length > 0) {
        seriesResponse.body.cards.forEach(card => {
          expect(['chair', 'sofa', 'desk', 'bed']).toContain(card.equipmentCode);
        });
      }
    });

    it('should display cards in 3-column grid layout', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.layout).toBeDefined();
      expect(response.body.layout.columns).toBe(3);
      expect(response.body.layout.cardSize).toBeDefined();
      expect(response.body.layout.spacing).toBeDefined();

      // 验证卡片网格数据
      if (response.body.cards.length > 0) {
        response.body.cards.forEach(card => {
          expect(card.thumbnailUrl).toBeDefined();
          expect(card.aspectRatio).toBe('9:13');
        });
      }
    });

    it('should support card detail view', async () => {
      // 先获取用户的卡片列表
      const cardsResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (cardsResponse.body.cards.length > 0) {
        const cardId = cardsResponse.body.cards[0].id;

        const detailResponse = await request(httpServer)
          .get(`/api/v1/cards/${cardId}/detail`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(detailResponse.body.card).toBeDefined();
        expect(detailResponse.body.card.id).toBe(cardId);
        expect(detailResponse.body.card.fullImageUrl).toBeDefined();
        expect(detailResponse.body.card.attributes).toBeDefined();
        expect(detailResponse.body.card.effects).toBeDefined();
        expect(detailResponse.body.card.history).toBeDefined();

        // 验证一键同款功能
        expect(detailResponse.body.copyWorkoutAction).toBeDefined();
        expect(detailResponse.body.copyWorkoutAction.deepLink).toBeDefined();
      }
    });

    it('should support multi-select for collage sharing', async () => {
      const cardsResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (cardsResponse.body.cards.length >= 3) {
        const selectedCardIds = cardsResponse.body.cards.slice(0, 3).map(card => card.id);

        const collageResponse = await request(httpServer)
          .post('/api/v1/cards/create-collage')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            cardIds: selectedCardIds,
            layout: '3x1',
          })
          .expect(201);

        expect(collageResponse.body.collageId).toBeDefined();
        expect(collageResponse.body.collageImageUrl).toBeDefined();
        expect(collageResponse.body.shareReady).toBe(true);
      }
    });
  });

  describe('6.3 训练历史Tab', () => {
    it('should display monthly calendar view', async () => {
      const currentDate = new Date();
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth() + 1;

      const response = await request(httpServer)
        .get('/api/v1/users/me/calendar')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ year, month })
        .expect(200);

      expect(response.body.calendar).toBeDefined();
      expect(response.body.calendar.year).toBe(year);
      expect(response.body.calendar.month).toBe(month);
      expect(response.body.calendar.days).toBeInstanceOf(Array);

      // 验证日期标记
      response.body.calendar.days.forEach(day => {
        expect(day).toHaveProperty('date');
        expect(day).toHaveProperty('workouts');
        expect(day).toHaveProperty('markers');

        if (day.workouts && day.workouts.length > 0) {
          expect(day.markers).toBeDefined();
          expect(day.markers.difficulty).toBeDefined();
          expect(day.markers.modes).toBeInstanceOf(Array);
        }
      });
    });

    it('should show workout details for selected date', async () => {
      const today = new Date().toISOString().split('T')[0];

      const response = await request(httpServer)
        .get('/api/v1/users/me/daily-workouts')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ date: today })
        .expect(200);

      expect(response.body.date).toBe(today);
      expect(response.body.workouts).toBeInstanceOf(Array);

      // 验证日训练详情
      if (response.body.workouts.length > 0) {
        const workout = response.body.workouts[0];
        expect(workout).toHaveProperty('sessionId');
        expect(workout).toHaveProperty('time');
        expect(workout).toHaveProperty('equipment');
        expect(workout).toHaveProperty('scenario');
        expect(workout).toHaveProperty('duration');
        expect(workout).toHaveProperty('exercises');
        expect(workout).toHaveProperty('copyAction');

        // 验证动作详情
        if (workout.exercises && workout.exercises.length > 0) {
          workout.exercises.forEach(exercise => {
            expect(exercise).toHaveProperty('name');
            expect(exercise).toHaveProperty('effect');
            expect(exercise).toHaveProperty('completed');
          });
        }
      }
    });

    it('should support "一键再练" functionality', async () => {
      // 获取历史会话
      const historyResponse = await request(httpServer)
        .get('/api/v1/users/me/workout-sessions')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ limit: 1 })
        .expect(200);

      if (historyResponse.body.sessions.length > 0) {
        const originalSessionId = historyResponse.body.sessions[0].id;

        const copyResponse = await request(httpServer)
          .post('/api/v1/workouts/copy-session')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            originalSessionId: originalSessionId,
          })
          .expect(201);

        expect(copyResponse.body.newSessionId).toBeDefined();
        expect(copyResponse.body.exercises.length).toBe(3);

        // 验证复刻的会话条件一致
        const newSession = await prisma.workoutSession.findUnique({
          where: { id: copyResponse.body.newSessionId },
        });

        const originalSession = await prisma.workoutSession.findUnique({
          where: { id: originalSessionId },
        });

        expect(newSession.intentType).toBe(originalSession.intentType);
        expect(newSession.difficulty).toBe(originalSession.difficulty);
      }
    });

    it('should calculate streak correctly', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/streak')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.currentStreak).toBeGreaterThanOrEqual(0);
      expect(response.body.longestStreak).toBeGreaterThanOrEqual(response.body.currentStreak);
      expect(response.body.streakDates).toBeInstanceOf(Array);

      // 验证连击计算逻辑
      if (response.body.currentStreak > 0) {
        expect(response.body.streakStartDate).toBeDefined();
        expect(response.body.isActiveToday).toBeDefined();
      }
    });

    it('should support date range filtering', async () => {
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(endDate.getDate() - 7); // 过去7天

      const response = await request(httpServer)
        .get('/api/v1/users/me/workout-sessions')
        .set('Authorization', `Bearer ${userToken}`)
        .query({
          startDate: startDate.toISOString().split('T')[0],
          endDate: endDate.toISOString().split('T')[0],
        })
        .expect(200);

      expect(response.body.sessions).toBeInstanceOf(Array);
      expect(response.body.dateRange).toBeDefined();
      expect(response.body.summary).toBeDefined();

      // 验证日期范围
      response.body.sessions.forEach(session => {
        const sessionDate = new Date(session.createdAt);
        expect(sessionDate).toBeGreaterThanOrEqual(startDate);
        expect(sessionDate).toBeLessThanOrEqual(endDate);
      });
    });
  });

  describe('6.4 个人设置Tab', () => {
    it('should display account settings', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/settings')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.account).toBeDefined();
      expect(response.body.account.isAnonymous).toBeDefined();
      expect(response.body.account.email).toBeDefined();

      // 如果是匿名用户，应该显示绑定邮箱选项
      if (response.body.account.isAnonymous) {
        expect(response.body.account.bindEmailAvailable).toBe(true);
      }
    });

    it('should support notification settings', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/settings/notifications')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.notifications).toBeDefined();
      expect(response.body.notifications.streakReminder).toBeDefined();
      expect(response.body.notifications.themeWeekReminder).toBeDefined();
      expect(response.body.notifications.quietHours).toBeDefined();

      // 测试更新通知设置
      const updateResponse = await request(httpServer)
        .patch('/api/v1/users/me/settings/notifications')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          streakReminder: true,
          themeWeekReminder: false,
          quietHours: {
            enabled: true,
            startTime: '22:00',
            endTime: '08:00',
          },
        })
        .expect(200);

      expect(updateResponse.body.updated).toBe(true);
    });

    it('should support privacy settings', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/settings/privacy')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.privacy).toBeDefined();
      expect(response.body.privacy.hidePhotos).toBeDefined();
      expect(response.body.privacy.faceBlur).toBeDefined();
      expect(response.body.privacy.photoUpload).toBeDefined();

      // 测试更新隐私设置
      const updateResponse = await request(httpServer)
        .patch('/api/v1/users/me/settings/privacy')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          hidePhotos: true,
          faceBlur: true,
          photoUpload: false,
        })
        .expect(200);

      expect(updateResponse.body.updated).toBe(true);

      // 验证设置已保存
      const verifyResponse = await request(httpServer)
        .get('/api/v1/users/me/settings/privacy')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(verifyResponse.body.privacy.hidePhotos).toBe(true);
      expect(verifyResponse.body.privacy.faceBlur).toBe(true);
    });

    it('should support language settings', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/settings/language')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.currentLanguage).toBeDefined();
      expect(response.body.availableLanguages).toBeInstanceOf(Array);

      // 测试切换语言
      const updateResponse = await request(httpServer)
        .patch('/api/v1/users/me/settings/language')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          language: 'en',
        })
        .expect(200);

      expect(updateResponse.body.updated).toBe(true);
      expect(updateResponse.body.newLanguage).toBe('en');
    });

    it('should provide data management options', async () => {
      const response = await request(httpServer)
        .get('/api/v1/users/me/settings/data')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.dataManagement).toBeDefined();
      expect(response.body.dataManagement.cacheSize).toBeDefined();
      expect(response.body.dataManagement.clearCacheAvailable).toBe(true);

      // 测试清理缓存
      const clearResponse = await request(httpServer)
        .post('/api/v1/users/me/settings/clear-cache')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(clearResponse.body.cleared).toBe(true);
      expect(clearResponse.body.freedSpace).toBeGreaterThan(0);
    });

    it('should enforce user data access restrictions', async () => {
      // 创建另一个用户
      const otherUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const otherUserToken = otherUserResponse.body.accessToken;
      const otherUserId = otherUserResponse.body.user.id;

      // 尝试访问其他用户的设置 (应该失败)
      await request(httpServer)
        .get(`/api/v1/users/${otherUserId}/settings`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(403);

      // 尝试修改其他用户的设置 (应该失败)
      await request(httpServer)
        .patch(`/api/v1/users/${otherUserId}/settings/privacy`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          hidePhotos: true,
        })
        .expect(403);
    });
  });

  describe('关键交互流验证', () => {
    it('should support card collection to sharing flow', async () => {
      // 获取卡片收集
      const cardsResponse = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      if (cardsResponse.body.cards.length > 0) {
        const cardId = cardsResponse.body.cards[0].id;

        // 查看卡片详情
        const detailResponse = await request(httpServer)
          .get(`/api/v1/cards/${cardId}/detail`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        // 执行分享
        const shareResponse = await request(httpServer)
          .post(`/api/v1/cards/${cardId}/share`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            platform: 'instagram',
          })
          .expect(200);

        expect(shareResponse.body.shareData).toBeDefined();

        // 执行一键同款
        const copyResponse = await request(httpServer)
          .post('/api/v1/workouts/copy-from-card')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            cardId: cardId,
          })
          .expect(201);

        expect(copyResponse.body.newSessionId).toBeDefined();
      }
    });

    it('should support history to re-practice flow', async () => {
      // 从历史记录选择某天
      const today = new Date().toISOString().split('T')[0];

      const dailyResponse = await request(httpServer)
        .get('/api/v1/users/me/daily-workouts')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ date: today })
        .expect(200);

      if (dailyResponse.body.workouts.length > 0) {
        const workout = dailyResponse.body.workouts[0];

        // 一键再练
        const repeatResponse = await request(httpServer)
          .post('/api/v1/workouts/copy-session')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            originalSessionId: workout.sessionId,
          })
          .expect(201);

        expect(repeatResponse.body.newSessionId).toBeDefined();
        expect(repeatResponse.body.exercises.length).toBe(3);
      }
    });

    it('should support missing card guidance flow', async () => {
      // 模拟查看缺失的卡片
      const missingResponse = await request(httpServer)
        .get('/api/v1/users/me/cards/missing')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(missingResponse.body.missingCards).toBeInstanceOf(Array);

      if (missingResponse.body.missingCards.length > 0) {
        const missingCard = missingResponse.body.missingCards[0];

        // 获取获得提示
        const hintResponse = await request(httpServer)
          .get(`/api/v1/cards/missing/${missingCard.equipmentCode}/hint`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(hintResponse.body.hint).toBeDefined();
        expect(hintResponse.body.suggestedActions).toBeInstanceOf(Array);

        // 一键同款入口
        if (hintResponse.body.suggestedActions.includes('try_workout')) {
          const tryResponse = await request(httpServer)
            .post('/api/v1/workouts/try-equipment')
            .set('Authorization', `Bearer ${userToken}`)
            .send({
              equipmentCode: missingCard.equipmentCode,
            })
            .expect(201);

          expect(tryResponse.body.sessionId).toBeDefined();
        }
      }
    });
  });

  describe('性能和用户体验验证', () => {
    it('should load user profile within 2 seconds', async () => {
      const startTime = Date.now();

      await request(httpServer)
        .get('/api/v1/users/me/profile')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(2000);
    });

    it('should handle large card collections efficiently', async () => {
      // 模拟大量卡片的场景
      const response = await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ limit: 50, offset: 0 })
        .expect(200);

      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.limit).toBe(50);
      expect(response.body.pagination.hasMore).toBeDefined();

      // 验证分页加载性能
      const startTime = Date.now();
      await request(httpServer)
        .get('/api/v1/users/me/cards')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ limit: 20, offset: 20 })
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(1500);
    });

    it('should support smooth tab switching', async () => {
      const tabRequests = [
        () => request(httpServer)
          .get('/api/v1/users/me/cards')
          .set('Authorization', `Bearer ${userToken}`),
        () => request(httpServer)
          .get('/api/v1/users/me/calendar')
          .set('Authorization', `Bearer ${userToken}`)
          .query({ year: new Date().getFullYear(), month: new Date().getMonth() + 1 }),
        () => request(httpServer)
          .get('/api/v1/users/me/settings')
          .set('Authorization', `Bearer ${userToken}`),
      ];

      const startTime = Date.now();
      const responses = await Promise.all(tabRequests.map(req => req()));
      const duration = Date.now() - startTime;

      responses.forEach(response => {
        expect(response.status).toBe(200);
      });

      expect(duration).toBeLessThan(3000); // 3个tab并发加载应该在3秒内完成
    });
  });
});
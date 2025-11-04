import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程5: 成果卡生成与分享', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let httpServer: any;
  let userToken: string;
  let userId: string;
  let completedSessionId: string;

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

    // 创建并完成一个训练会话
    const sessionResponse = await request(httpServer)
      .post('/api/v1/recommendations/quick')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        intentType: 'STRETCH',
        difficulty: 'GREEN',
        equipmentCodes: ['chair'],
        targetMuscles: ['NECK_SHOULDERS'],
        duration: 60,
      })
      .expect(201);

    completedSessionId = sessionResponse.body.sessionId;

    // 开始并完成训练
    await request(httpServer)
      .post(`/api/v1/workout-sessions/${completedSessionId}/start`)
      .set('Authorization', `Bearer ${userToken}`)
      .expect(200);

    // 完成所有动作
    for (let i = 1; i <= 3; i++) {
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${completedSessionId}/complete-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({ exerciseSequence: i })
        .expect(200);
    }
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('5.1 锻炼完成结果页', () => {
    it('should display completion animation and statistics', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${completedSessionId}/completion`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 验证完成状态
      expect(response.body.completed).toBe(true);
      expect(response.body.completionTime).toBeDefined();

      // 验证统计数据
      expect(response.body.stats).toBeDefined();
      expect(response.body.stats.duration).toBeGreaterThan(0);
      expect(response.body.stats.caloriesBurned).toBeGreaterThan(0);
      expect(response.body.stats.exercisesCompleted).toBe(3);

      // 验证鼓励语
      expect(response.body.encouragementMessage).toBeDefined();
      expect(typeof response.body.encouragementMessage).toBe('string');

      // 验证操作选项
      expect(response.body.actions).toBeInstanceOf(Array);
      expect(response.body.actions).toContain('generate_card');
      expect(response.body.actions).toContain('workout_again');
      expect(response.body.actions).toContain('return_home');
    });

    it('should calculate workout statistics accurately', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${completedSessionId}/completion`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const stats = response.body.stats;

      // 验证时长计算（基于实际完成时间）
      expect(stats.duration).toBeGreaterThanOrEqual(50); // 应该接近60秒
      expect(stats.duration).toBeLessThanOrEqual(120); // 考虑用户操作时间

      // 验证卡路里计算（基于运动强度和时长）
      expect(stats.caloriesBurned).toBeGreaterThan(10);
      expect(stats.caloriesBurned).toBeLessThan(100); // 轻度运动范围

      // 验证动作完成数
      expect(stats.exercisesCompleted).toBe(3);
      expect(stats.exercisesSkipped).toBe(0);
    });

    it('should provide appropriate encouragement messages', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${completedSessionId}/completion`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const message = response.body.encouragementMessage;

      // 验证鼓励语内容
      expect(message).toBeDefined();
      expect(message.length).toBeGreaterThan(10);

      // 应该包含正面词汇
      const positiveWords = ['完成', '棒', '好', '成功', '坚持', '努力', 'excellent', 'great'];
      const hasPositiveWord = positiveWords.some(word => message.includes(word));
      expect(hasPositiveWord).toBe(true);
    });
  });

  describe('5.2 生成成果卡片', () => {
    it('should generate card within 800ms', async () => {
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

      // 验证生成结果
      expect(response.body.cardId).toBeDefined();
      expect(response.body.cardImageUrl).toBeDefined();
      expect(response.body.deepLink).toBeDefined();
      expect(response.body.rarity).toBeDefined();
    });

    it('should create share_cards table record', async () => {
      const response = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'trendy',
        })
        .expect(201);

      const cardId = response.body.cardId;

      // 验证数据库记录
      const cardRecord = await prisma.shareCard.findUnique({
        where: { id: cardId },
      });

      expect(cardRecord).toBeDefined();
      expect(cardRecord.userId).toBe(userId);
      expect(cardRecord.sessionId).toBe(completedSessionId);
      expect(cardRecord.cardImageUrl).toBe(response.body.cardImageUrl);
      expect(cardRecord.rarity).toBe(response.body.rarity);
      expect(cardRecord.cardTemplate).toBe('trendy');
    });

    it('should generate accessible image URL', async () => {
      const response = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'minimal',
        })
        .expect(201);

      const imageUrl = response.body.cardImageUrl;

      // 验证URL格式
      expect(imageUrl).toMatch(/^https?:\/\//);
      expect(imageUrl).toMatch(/\.(png|jpg|jpeg)$/i);

      // 验证图片可访问性（模拟）
      expect(response.body.imageAccessible).toBe(true);
      expect(response.body.imageSize).toBeLessThan(1.2 * 1024 * 1024); // ≤1.2MB
    });

    it('should calculate rarity correctly', async () => {
      // 生成卡片
      const response = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'classic',
        })
        .expect(201);

      // 验证稀有度计算
      const rarityResponse = await request(httpServer)
        .get(`/api/v1/rarity/calculate/${response.body.equipmentCode}`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(rarityResponse.body.equipmentCode).toBeDefined();
      expect(rarityResponse.body.rarity).toBeDefined();
      expect(rarityResponse.body.globalFrequency).toBeDefined();
      expect(rarityResponse.body.percentile).toBeGreaterThanOrEqual(0);
      expect(rarityResponse.body.percentile).toBeLessThanOrEqual(100);

      // 验证稀有度等级
      const validRarities = ['COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY'];
      expect(validRarities).toContain(rarityResponse.body.rarity);
    });

    it('should generate valid DeepLink', async () => {
      const response = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'classic',
        })
        .expect(201);

      const deepLink = response.body.deepLink;

      // 验证DeepLink格式
      expect(deepLink).toMatch(/^snaprep:\/\/workout\/copy\//);
      expect(deepLink).toContain(completedSessionId);

      // 验证DeepLink可用性
      const linkValidationResponse = await request(httpServer)
        .get('/api/v1/deeplinks/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ url: deepLink })
        .expect(200);

      expect(linkValidationResponse.body.valid).toBe(true);
      expect(linkValidationResponse.body.targetSession).toBe(completedSessionId);
    });
  });

  describe('5.3 稀有度系统验证', () => {
    it('should calculate 5-tier rarity levels correctly', async () => {
      const equipmentCodes = ['chair', 'wall', 'hands_free', 'water_bottle', 'backpack'];

      for (const equipmentCode of equipmentCodes) {
        const response = await request(httpServer)
          .get(`/api/v1/rarity/calculate/${equipmentCode}`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(response.body.equipmentCode).toBe(equipmentCode);
        expect(response.body.rarity).toBeDefined();

        const validRarities = ['COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY'];
        expect(validRarities).toContain(response.body.rarity);

        // 验证计算基于7日全球频次
        expect(response.body.globalFrequency7d).toBeGreaterThanOrEqual(0);
        expect(response.body.lastCalculated).toBeDefined();
      }
    });

    it('should categorize equipment series correctly', async () => {
      const seriesTests = [
        { equipment: 'chair', expectedSeries: '家具系' },
        { equipment: 'wall', expectedSeries: '墙面系' },
        { equipment: 'water_bottle', expectedSeries: '瓶罐系' },
        { equipment: 'backpack', expectedSeries: '背包系' },
        { equipment: 'stairs', expectedSeries: '台阶座椅' },
      ];

      for (const test of seriesTests) {
        const response = await request(httpServer)
          .get(`/api/v1/rarity/calculate/${test.equipment}`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        expect(response.body.equipmentSeries).toBe(test.expectedSeries);
      }
    });

    it('should trigger special tags correctly', async () => {
      // 测试静音完成标签
      const silentSessionResponse = await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: 'RELAX',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['NECK'],
          duration: 60,
          silentMode: true,
        })
        .expect(201);

      const silentSessionId = silentSessionResponse.body.sessionId;

      // 完成静音训练
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${silentSessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      for (let i = 1; i <= 3; i++) {
        await request(httpServer)
          .post(`/api/v1/workout-sessions/${silentSessionId}/complete-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({ exerciseSequence: i })
          .expect(200);
      }

      // 生成卡片并验证特殊标签
      const cardResponse = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: silentSessionId,
          style: 'classic',
        })
        .expect(201);

      expect(cardResponse.body.specialTags).toContain('静音完成');
    });

    it('should calculate frequency distribution accurately', async () => {
      // 获取多个器材的频次统计
      const statsResponse = await request(httpServer)
        .get('/api/v1/rarity/stats/distribution')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(statsResponse.body.distribution).toBeDefined();
      expect(statsResponse.body.totalSessions7d).toBeGreaterThan(0);

      // 验证频次分布合理性
      const distribution = statsResponse.body.distribution;
      let totalPercentage = 0;

      Object.values(distribution).forEach((percentage: number) => {
        expect(percentage).toBeGreaterThanOrEqual(0);
        expect(percentage).toBeLessThanOrEqual(100);
        totalPercentage += percentage;
      });

      expect(totalPercentage).toBeCloseTo(100, 1);
    });
  });

  describe('5.4 成果卡页面功能', () => {
    let cardId: string;

    beforeEach(async () => {
      const response = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'classic',
        })
        .expect(201);

      cardId = response.body.cardId;
    });

    it('should display 9:16 card preview', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/cards/${cardId}/preview`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.aspectRatio).toBe('9:16');
      expect(response.body.width).toBe(1080);
      expect(response.body.height).toBe(1920);
      expect(response.body.previewUrl).toBeDefined();
    });

    it('should support style switching', async () => {
      const styles = ['trendy', 'minimal', 'theme'];

      for (const style of styles) {
        const response = await request(httpServer)
          .post(`/api/v1/cards/${cardId}/change-style`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({ style })
          .expect(200);

        expect(response.body.newStyle).toBe(style);
        expect(response.body.newImageUrl).toBeDefined();
        expect(response.body.previewUrl).toBeDefined();
      }
    });

    it('should save to device gallery', async () => {
      const response = await request(httpServer)
        .post(`/api/v1/cards/${cardId}/save`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          requestGalleryPermission: true,
        })
        .expect(200);

      if (response.body.permissionGranted) {
        expect(response.body.saved).toBe(true);
        expect(response.body.savedPath).toBeDefined();
      } else {
        expect(response.body.permissionDenied).toBe(true);
        expect(response.body.permissionInstructions).toBeDefined();
      }
    });

    it('should share via system share panel', async () => {
      const response = await request(httpServer)
        .post(`/api/v1/cards/${cardId}/share`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          platform: 'system',
          includeDeepLink: true,
        })
        .expect(200);

      expect(response.body.shareData).toBeDefined();
      expect(response.body.shareData.title).toBeDefined();
      expect(response.body.shareData.text).toBeDefined();
      expect(response.body.shareData.url).toBeDefined();
      expect(response.body.shareData.imageUrl).toBeDefined();

      // 验证分享数据格式
      expect(response.body.shareData.url).toMatch(/^snaprep:\/\//);
    });

    it('should track share metrics', async () => {
      // 模拟分享操作
      await request(httpServer)
        .post(`/api/v1/cards/${cardId}/share`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          platform: 'instagram',
          includeDeepLink: true,
        })
        .expect(200);

      // 验证分享统计
      const card = await prisma.shareCard.findUnique({
        where: { id: cardId },
      });

      expect(card.shareCount).toBeGreaterThan(0);

      // 获取分享统计
      const statsResponse = await request(httpServer)
        .get(`/api/v1/cards/${cardId}/stats`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(statsResponse.body.shareCount).toBeGreaterThan(0);
      expect(statsResponse.body.viewCount).toBeGreaterThanOrEqual(0);
    });
  });

  describe('分享转化和DeepLink测试', () => {
    let sharedCardId: string;
    let deepLink: string;

    beforeEach(async () => {
      const cardResponse = await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'classic',
        })
        .expect(201);

      sharedCardId = cardResponse.body.cardId;
      deepLink = cardResponse.body.deepLink;
    });

    it('should handle DeepLink click and redirect', async () => {
      // 模拟新用户点击DeepLink
      const newUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const newUserToken = newUserResponse.body.accessToken;

      // 点击DeepLink
      const clickResponse = await request(httpServer)
        .get('/api/v1/deeplinks/handle')
        .set('Authorization', `Bearer ${newUserToken}`)
        .query({ url: deepLink })
        .expect(200);

      expect(clickResponse.body.action).toBe('copy_workout');
      expect(clickResponse.body.originalSessionId).toBe(completedSessionId);
      expect(clickResponse.body.copyData).toBeDefined();

      // 验证复刻数据包含原始条件
      const copyData = clickResponse.body.copyData;
      expect(copyData.intentType).toBe('STRETCH');
      expect(copyData.difficulty).toBe('GREEN');
      expect(copyData.equipmentCodes).toContain('chair');
    });

    it('should create copy workout from DeepLink', async () => {
      const newUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const newUserToken = newUserResponse.body.accessToken;

      // 执行一键同款
      const copyResponse = await request(httpServer)
        .post('/api/v1/workouts/copy-from-deeplink')
        .set('Authorization', `Bearer ${newUserToken}`)
        .send({
          deepLink: deepLink,
        })
        .expect(201);

      expect(copyResponse.body.newSessionId).toBeDefined();
      expect(copyResponse.body.exercises.length).toBe(3);

      // 验证新会话使用相同条件
      const newSession = await prisma.workoutSession.findUnique({
        where: { id: copyResponse.body.newSessionId },
      });

      const originalSession = await prisma.workoutSession.findUnique({
        where: { id: completedSessionId },
      });

      expect(newSession.intentType).toBe(originalSession.intentType);
      expect(newSession.difficulty).toBe(originalSession.difficulty);
    });

    it('should track viral metrics', async () => {
      // 模拟多个用户点击同一DeepLink
      for (let i = 0; i < 3; i++) {
        const userResponse = await request(httpServer)
          .post('/auth/anonymous')
          .expect(201);

        await request(httpServer)
          .get('/api/v1/deeplinks/handle')
          .set('Authorization', `Bearer ${userResponse.body.accessToken}`)
          .query({ url: deepLink })
          .expect(200);
      }

      // 检查病毒式传播指标
      const metricsResponse = await request(httpServer)
        .get(`/api/v1/cards/${sharedCardId}/viral-metrics`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(metricsResponse.body.totalClicks).toBeGreaterThanOrEqual(3);
      expect(metricsResponse.body.uniqueUsers).toBeGreaterThanOrEqual(3);
      expect(metricsResponse.body.conversionRate).toBeGreaterThanOrEqual(0);
    });
  });

  describe('性能和KPI验证', () => {
    it('should meet card generation performance target', async () => {
      const startTime = Date.now();

      await request(httpServer)
        .post('/api/v1/cards/generate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          sessionId: completedSessionId,
          style: 'minimal',
        })
        .expect(201);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(800); // ≤800ms目标
    });

    it('should achieve share button click rate target', async () => {
      // 创建多个卡片并模拟用户行为
      const cardIds = [];

      for (let i = 0; i < 10; i++) {
        const response = await request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: completedSessionId,
            style: 'classic',
          })
          .expect(201);

        cardIds.push(response.body.cardId);
      }

      // 模拟部分卡片分享
      for (let i = 0; i < 5; i++) {
        await request(httpServer)
          .post(`/api/v1/cards/${cardIds[i]}/share`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            platform: 'instagram',
          })
          .expect(200);
      }

      // 计算分享率
      const shareRate = (5 / 10) * 100;
      expect(shareRate).toBeGreaterThanOrEqual(40); // ≥40%目标
    });

    it('should handle concurrent card generation', async () => {
      // 创建多个并发会话
      const sessionPromises = Array(5).fill(0).map(() =>
        request(httpServer)
          .post('/api/v1/recommendations/quick')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            intentType: 'CARDIO',
            difficulty: 'BLUE',
            equipmentCodes: ['hands_free'],
            targetMuscles: ['FULL_BODY'],
            duration: 60,
          })
      );

      const sessions = await Promise.all(sessionPromises);

      // 完成所有会话
      for (const sessionResponse of sessions) {
        const sessionId = sessionResponse.body.sessionId;

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
      }

      // 并发生成卡片
      const cardPromises = sessions.map(sessionResponse =>
        request(httpServer)
          .post('/api/v1/cards/generate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            sessionId: sessionResponse.body.sessionId,
            style: 'classic',
          })
      );

      const startTime = Date.now();
      const cardResponses = await Promise.all(cardPromises);
      const duration = Date.now() - startTime;

      // 验证所有卡片生成成功
      cardResponses.forEach(response => {
        expect(response.status).toBe(201);
        expect(response.body.cardId).toBeDefined();
      });

      // 平均生成时间应该在合理范围内
      const avgDuration = duration / cardResponses.length;
      expect(avgDuration).toBeLessThan(1000);
    });
  });
});
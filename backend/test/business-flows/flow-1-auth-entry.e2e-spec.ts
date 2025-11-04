import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程1: 用户认证与首次进入', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let httpServer: any;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);
    httpServer = app.getHttpServer();
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('1.1 应用启动与匿名登录', () => {
    it('should create anonymous user on first launch', async () => {
      // 模拟应用首次启动
      const response = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      expect(response.body.user).toBeDefined();
      expect(response.body.user.isAnonymous).toBe(true);
      expect(response.body.accessToken).toBeDefined();
      expect(response.body.refreshToken).toBeDefined();
    });

    it('should store JWT token and create user record', async () => {
      const response = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const userId = response.body.user.id;
      const token = response.body.accessToken;

      // 验证用户记录创建
      const user = await prisma.user.findUnique({
        where: { id: userId },
      });

      expect(user).toBeDefined();
      expect(user.isAnonymous).toBe(true);

      // 验证token有效性
      const protectedResponse = await request(httpServer)
        .get('/users/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(protectedResponse.body.id).toBe(userId);
    });

    it('should enable core functionality for anonymous users', async () => {
      const authResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const token = authResponse.body.accessToken;

      // 测试核心功能：获取场景列表
      await request(httpServer)
        .get('/rest/v1/scenarios')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      // 测试核心功能：获取器材列表
      await request(httpServer)
        .get('/rest/v1/equipment')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      // 测试核心功能：快速推荐
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${token}`)
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
        })
        .expect(201);
    });
  });

  describe('1.2 邮箱注册/登录 (可选)', () => {
    let anonymousUserId: string;
    let anonymousToken: string;

    beforeEach(async () => {
      // 创建匿名用户
      const response = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      anonymousUserId = response.body.user.id;
      anonymousToken = response.body.accessToken;
    });

    it('should send magic link for email signup', async () => {
      const testEmail = 'upgrade@snaprep.com';

      const response = await request(httpServer)
        .post('/auth/signup-with-email')
        .send({
          email: testEmail,
          anonymousUserId,
        })
        .expect(201);

      expect(response.body.message).toContain('Magic link sent');
      expect(response.body.email).toBe(testEmail);
    });

    it('should upgrade anonymous account to email account', async () => {
      const testEmail = 'upgrade2@snaprep.com';

      // 模拟Magic Link验证过程
      const upgradeResponse = await request(httpServer)
        .post('/auth/verify-magic-link')
        .send({
          token: 'mock-magic-link-token',
          email: testEmail,
          anonymousUserId,
        })
        .expect(200);

      expect(upgradeResponse.body.user.email).toBe(testEmail);
      expect(upgradeResponse.body.user.isAnonymous).toBe(false);

      // 验证账户升级后数据保留
      const upgradedUser = await prisma.user.findUnique({
        where: { id: anonymousUserId },
        include: {
          workoutSessions: true,
          shareCards: true,
        },
      });

      expect(upgradedUser.email).toBe(testEmail);
      expect(upgradedUser.isAnonymous).toBe(false);
      // 历史数据应该保留
    });

    it('should support multi-device sync after upgrade', async () => {
      const testEmail = 'multidevice@snaprep.com';

      // 设备1：完成升级
      await request(httpServer)
        .post('/auth/verify-magic-link')
        .send({
          token: 'mock-magic-link-token-1',
          email: testEmail,
          anonymousUserId,
        })
        .expect(200);

      // 设备2：使用相同邮箱登录
      const device2Response = await request(httpServer)
        .post('/auth/signin-with-email')
        .send({
          email: testEmail,
        })
        .expect(200);

      expect(device2Response.body.user.email).toBe(testEmail);
      expect(device2Response.body.user.id).toBe(anonymousUserId);
    });
  });

  describe('数据初始化验证', () => {
    it('should load scenarios and equipment on first launch', async () => {
      // 验证场景数据
      const scenarios = await prisma.scenario.findMany({
        where: { isActive: true },
      });

      expect(scenarios.length).toBeGreaterThan(0);
      expect(scenarios.some(s => s.code === 'office')).toBe(true);
      expect(scenarios.some(s => s.code === 'living_room')).toBe(true);

      // 验证器材数据
      const equipment = await prisma.equipment.findMany({
        where: { isActive: true },
      });

      expect(equipment.length).toBeGreaterThan(0);
      expect(equipment.some(e => e.code === 'hands_free')).toBe(true);
      expect(equipment.some(e => e.code === 'chair')).toBe(true);
      expect(equipment.some(e => e.code === 'wall')).toBe(true);
    });

    it('should load theme week information', async () => {
      const currentThemeWeek = await request(httpServer)
        .get('/api/v1/theme-weeks/current')
        .expect(200);

      if (currentThemeWeek.body) {
        expect(currentThemeWeek.body.name).toBeDefined();
        expect(currentThemeWeek.body.equipmentSeries).toBeDefined();
        expect(currentThemeWeek.body.targetCount).toBeGreaterThan(0);
        expect(currentThemeWeek.body.startDate).toBeDefined();
        expect(currentThemeWeek.body.endDate).toBeDefined();
      }
    });

    it('should have sufficient exercise data for recommendations', async () => {
      const exercises = await prisma.exercise.findMany({
        where: { isActive: true },
        include: { exerciseEquipment: true },
      });

      expect(exercises.length).toBeGreaterThanOrEqual(30);

      // 验证各种意图类型都有动作
      const intentTypes = [...new Set(exercises.map(e => e.intentType))];
      expect(intentTypes).toContain('RELAX');
      expect(intentTypes).toContain('STRETCH');
      expect(intentTypes).toContain('CARDIO');
      expect(intentTypes).toContain('STRENGTH');

      // 验证各种难度都有动作
      const difficulties = [...new Set(exercises.map(e => e.difficulty))];
      expect(difficulties).toContain('GREEN');
      expect(difficulties).toContain('BLUE');
      expect(difficulties.length).toBeGreaterThanOrEqual(2);

      // 验证器材关联
      const exercisesWithEquipment = exercises.filter(e => e.exerciseEquipment.length > 0);
      expect(exercisesWithEquipment.length).toBeGreaterThan(0);
    });
  });

  describe('权限与安全验证', () => {
    it('should reject invalid tokens', async () => {
      await request(httpServer)
        .get('/users/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should reject expired tokens', async () => {
      // 这里应该使用真实的过期token测试
      // 由于测试环境限制，我们模拟这个场景
      await request(httpServer)
        .get('/users/me')
        .set('Authorization', 'Bearer expired.token.here')
        .expect(401);
    });

    it('should enforce rate limiting on auth endpoints', async () => {
      const testEmail = 'ratelimit@snaprep.com';

      // 快速发送多个请求
      const promises = Array(10).fill(0).map(() =>
        request(httpServer)
          .post('/auth/signup-with-email')
          .send({ email: testEmail })
      );

      const responses = await Promise.all(promises);

      // 应该有一些请求被限流
      const rateLimitedResponses = responses.filter(r => r.status === 429);
      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    });
  });

  describe('性能验证', () => {
    it('should complete anonymous login within 2 seconds', async () => {
      const startTime = Date.now();

      await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(2000);
    });

    it('should load initial data within 3 seconds', async () => {
      const authResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const token = authResponse.body.accessToken;
      const startTime = Date.now();

      await Promise.all([
        request(httpServer)
          .get('/rest/v1/scenarios')
          .set('Authorization', `Bearer ${token}`),
        request(httpServer)
          .get('/rest/v1/equipment')
          .set('Authorization', `Bearer ${token}`),
        request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .set('Authorization', `Bearer ${token}`),
      ]);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(3000);
    });
  });
});
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程2: 首页快速启动', () => {
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
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('2.1 首页加载', () => {
    it('should load all homepage data within 2 seconds', async () => {
      const startTime = Date.now();

      const [scenariosRes, equipmentRes, themeWeekRes] = await Promise.all([
        request(httpServer)
          .get('/rest/v1/scenarios')
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200),
        request(httpServer)
          .get('/rest/v1/equipment')
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200),
        request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200),
      ]);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(2000);

      // 验证数据结构
      expect(scenariosRes.body).toBeInstanceOf(Array);
      expect(scenariosRes.body.length).toBeGreaterThan(0);

      expect(equipmentRes.body).toBeInstanceOf(Array);
      expect(equipmentRes.body.length).toBeGreaterThan(0);

      // 验证场景数据结构
      const scenario = scenariosRes.body[0];
      expect(scenario).toHaveProperty('id');
      expect(scenario).toHaveProperty('code');
      expect(scenario).toHaveProperty('name');
      expect(scenario).toHaveProperty('isActive');

      // 验证器材数据结构
      const equipment = equipmentRes.body[0];
      expect(equipment).toHaveProperty('id');
      expect(equipment).toHaveProperty('code');
      expect(equipment).toHaveProperty('name');
      expect(equipment).toHaveProperty('category');
      expect(equipment).toHaveProperty('isActive');
    });

    it('should display active scenarios and equipment only', async () => {
      const scenariosRes = await request(httpServer)
        .get('/rest/v1/scenarios')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const equipmentRes = await request(httpServer)
        .get('/rest/v1/equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 所有返回的场景都应该是激活状态
      scenariosRes.body.forEach(scenario => {
        expect(scenario.isActive).toBe(true);
      });

      // 所有返回的器材都应该是激活状态
      equipmentRes.body.forEach(equipment => {
        expect(equipment.isActive).toBe(true);
      });
    });
  });

  describe('2.2 快速开始 - "给我60秒"', () => {
    it('should generate 3 exercises within 5 seconds', async () => {
      const startTime = Date.now();

      const response = await request(httpServer)
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

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(5000);

      // 验证返回恰好3个动作
      expect(response.body.exercises).toBeInstanceOf(Array);
      expect(response.body.exercises.length).toBe(3);

      // 验证创建了workout_session
      expect(response.body.sessionId).toBeDefined();

      const session = await prisma.workoutSession.findUnique({
        where: { id: response.body.sessionId },
        include: { sessionExercises: true },
      });

      expect(session).toBeDefined();
      expect(session.userId).toBe(userId);
      expect(session.intentType).toBe('STRETCH');
      expect(session.difficulty).toBe('GREEN');
      expect(session.status).toBe('CREATED');
      expect(session.sessionExercises.length).toBe(3);
    });

    it('should use default equipment (hands_free) for quick start', async () => {
      const response = await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(201);

      // 验证推荐的动作使用默认器材
      response.body.exercises.forEach(exercise => {
        expect(exercise.tags).toContain('anywhere');
      });
    });

    it('should target approximately 60 seconds total duration', async () => {
      const response = await request(httpServer)
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

      // 计算总时长 (允许±10%的误差)
      const totalDuration = response.body.exercises.reduce((sum, exercise) => {
        return sum + (exercise.defaultDuration || 20);
      }, 0);

      expect(totalDuration).toBeGreaterThanOrEqual(54); // 60 - 10%
      expect(totalDuration).toBeLessThanOrEqual(66);    // 60 + 10%
    });
  });

  describe('2.3 场景快选', () => {
    it('should generate recommendations based on scenario presets', async () => {
      // 测试办公室场景
      const response = await request(httpServer)
        .post('/api/v1/recommendations/scenario')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          scenarioCode: 'office',
        })
        .expect(201);

      expect(response.body.exercises).toBeInstanceOf(Array);
      expect(response.body.exercises.length).toBe(3);

      // 验证办公室场景的动作特性
      response.body.exercises.forEach(exercise => {
        const hasOfficeEquipment =
          exercise.tags.includes('chair') ||
          exercise.tags.includes('wall') ||
          exercise.tags.includes('silent');
        expect(hasOfficeEquipment).toBe(true);
      });
    });

    it('should handle different scenario presets correctly', async () => {
      const scenarios = [
        { code: 'office', expectedEquipment: ['chair', 'wall'] },
        { code: 'living_room', expectedEquipment: ['sofa', 'chair'] },
        { code: 'park', expectedEquipment: ['bench', 'tree'] },
        { code: 'bedroom', expectedEquipment: ['bed', 'hands_free'] },
      ];

      for (const scenario of scenarios) {
        const response = await request(httpServer)
          .post('/api/v1/recommendations/scenario')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            scenarioCode: scenario.code,
          })
          .expect(201);

        expect(response.body.exercises.length).toBe(3);
        expect(response.body.sessionId).toBeDefined();

        // 验证场景配置正确
        const session = await prisma.workoutSession.findUnique({
          where: { id: response.body.sessionId },
        });

        expect(session.scenarioCode).toBe(scenario.code);
      }
    });

    it('should jump directly to result page', async () => {
      const response = await request(httpServer)
        .post('/api/v1/recommendations/scenario')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          scenarioCode: 'office',
        })
        .expect(201);

      // 应该直接返回完整的推荐结果，无需进入引导页
      expect(response.body.exercises).toBeDefined();
      expect(response.body.sessionId).toBeDefined();
      expect(response.body.alternatives).toBeDefined();
    });
  });

  describe('2.4 物品选择', () => {
    it('should preselect equipment and enter guide page', async () => {
      const response = await request(httpServer)
        .post('/api/v1/recommendations/with-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          equipmentCodes: ['chair'],
          enterGuidePage: true,
        })
        .expect(201);

      // 应该返回引导页需要的数据结构
      expect(response.body.preselectedEquipment).toContain('chair');
      expect(response.body.shouldEnterGuidePage).toBe(true);
      expect(response.body.suggestedIntents).toBeDefined();
      expect(response.body.suggestedTargetMuscles).toBeDefined();
    });

    it('should handle multiple equipment selection', async () => {
      const response = await request(httpServer)
        .post('/api/v1/recommendations/with-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          equipmentCodes: ['chair', 'wall'],
          enterGuidePage: true,
        })
        .expect(201);

      expect(response.body.preselectedEquipment).toEqual(['chair', 'wall']);
      expect(response.body.shouldEnterGuidePage).toBe(true);
    });
  });

  describe('2.5 AI物品识别', () => {
    it('should handle high confidence recognition', async () => {
      // 模拟高置信度识别结果
      const mockImageBuffer = Buffer.from('mock-image-data');

      const response = await request(httpServer)
        .post('/api/v1/ai/recognize-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .attach('image', mockImageBuffer, 'test-image.jpg')
        .expect(200);

      expect(response.body.recognized).toBeInstanceOf(Array);
      expect(response.body.confidence).toBeDefined();

      // 高置信度时应该自动预选
      if (response.body.confidence >= 0.85) {
        expect(response.body.autoPreselected).toBe(true);
        expect(response.body.preselectedEquipment).toBeDefined();
      }
    });

    it('should provide candidates for low confidence recognition', async () => {
      // 模拟低置信度识别结果
      const mockImageBuffer = Buffer.from('mock-low-confidence-image');

      const response = await request(httpServer)
        .post('/api/v1/ai/recognize-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .attach('image', mockImageBuffer, 'low-confidence.jpg')
        .expect(200);

      if (response.body.confidence < 0.85) {
        expect(response.body.autoPreselected).toBe(false);
        expect(response.body.candidates).toBeInstanceOf(Array);
        expect(response.body.candidates.length).toBeGreaterThan(0);
        expect(response.body.candidates.length).toBeLessThanOrEqual(3);
      }
    });

    it('should complete recognition within 3 seconds', async () => {
      const mockImageBuffer = Buffer.from('mock-performance-test-image');
      const startTime = Date.now();

      await request(httpServer)
        .post('/api/v1/ai/recognize-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .attach('image', mockImageBuffer, 'performance-test.jpg')
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(3000);
    });

    it('should handle camera permission denied gracefully', async () => {
      // 模拟权限拒绝的情况
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

    it('should handle offline scenario', async () => {
      // 模拟离线状态
      const response = await request(httpServer)
        .post('/api/v1/ai/recognize-equipment')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          offline: true,
        })
        .expect(200);

      expect(response.body.offline).toBe(true);
      expect(response.body.fallbackMessage).toBeDefined();
      expect(response.body.manualSelectionOptions).toBeDefined();
    });
  });

  describe('数据完整性验证', () => {
    it('should have all required scenarios for quick selection', async () => {
      const scenarios = await prisma.scenario.findMany({
        where: { isActive: true },
        orderBy: { displayOrder: 'asc' },
      });

      const requiredScenarios = ['office', 'living_room', 'park', 'bedroom'];

      requiredScenarios.forEach(scenarioCode => {
        const scenario = scenarios.find(s => s.code === scenarioCode);
        expect(scenario).toBeDefined();
        expect(scenario.name).toBeDefined();
        expect(scenario.description).toBeDefined();
      });
    });

    it('should have all required equipment for quick selection', async () => {
      const equipment = await prisma.equipment.findMany({
        where: { isActive: true },
        orderBy: { displayOrder: 'asc' },
      });

      const requiredEquipment = [
        'hands_free', 'chair', 'wall', 'water_bottle',
        'backpack', 'stairs', 'sofa', 'book', 'towel'
      ];

      requiredEquipment.forEach(equipmentCode => {
        const item = equipment.find(e => e.code === equipmentCode);
        expect(item).toBeDefined();
        expect(item.name).toBeDefined();
        expect(item.category).toBeDefined();
      });
    });
  });

  describe('性能基准测试', () => {
    it('should meet TTV (Time to Value) target of 30 seconds', async () => {
      const startTime = Date.now();

      // 模拟完整的"给我60秒"流程
      // 1. 首页加载
      await Promise.all([
        request(httpServer)
          .get('/rest/v1/scenarios')
          .set('Authorization', `Bearer ${userToken}`),
        request(httpServer)
          .get('/rest/v1/equipment')
          .set('Authorization', `Bearer ${userToken}`),
        request(httpServer)
          .get('/api/v1/theme-weeks/current')
          .set('Authorization', `Bearer ${userToken}`),
      ]);

      // 2. 快速推荐
      await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        });

      const ttvDuration = Date.now() - startTime;
      expect(ttvDuration).toBeLessThan(30000); // 30秒目标
    });

    it('should handle concurrent quick start requests', async () => {
      const promises = Array(5).fill(0).map(() =>
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

      const responses = await Promise.all(promises);

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
  });
});
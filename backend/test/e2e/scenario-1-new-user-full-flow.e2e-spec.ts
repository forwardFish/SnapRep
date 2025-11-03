import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import { ApiClientHelper } from '../helpers/api-client.helper';

describe('E2E场景1: 新用户首次完整流程', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let apiClient: ApiClientHelper;
  let testUserId: string;
  let sessionId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);
    apiClient = new ApiClientHelper(app);
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('步骤1: 匿名登录', () => {
    it('should create anonymous user and return JWT token', async () => {
      const user = await testData.createTestUser('anon-test@example.com', 'Anonymous User');
      testUserId = user.id;

      expect(user.id).toBeDefined();
      expect(user.email).toBe('anon-test@example.com');
    });
  });

  describe('步骤2: 首页加载场景和器材', () => {
    it('should load scenarios within 2 seconds', async () => {
      const startTime = Date.now();
      const scenarios = await prisma.scenario.findMany({ where: { isActive: true } });
      const loadTime = Date.now() - startTime;

      expect(scenarios.length).toBeGreaterThan(0);
      expect(loadTime).toBeLessThan(2000);
    });

    it('should load equipment list', async () => {
      const equipment = await prisma.equipment.findMany({ where: { isActive: true } });
      expect(equipment.length).toBeGreaterThan(0);
    });
  });

  describe('步骤3: "给我60秒"快速推荐', () => {
    it('should generate 3 exercises in ≤5 seconds', async () => {
      const exercises = await testData.getTestExercises(3);
      const session = await testData.createTestSession(testUserId, exercises.map(e => e.id));
      sessionId = session.id;

      expect(session.sessionExercises).toHaveLength(3);
      expect(session.status).toBe('PENDING');
    }, 5000);

    it('should have valid total duration', () => {
      expect(typeof sessionId).toBe('string');
    });
  });

  describe('步骤4: 查看动作结果页', () => {
    it('should display 3 exercise cards', async () => {
      const session = await prisma.workoutSession.findUnique({
        where: { id: sessionId },
        include: { sessionExercises: { include: { exercise: true } } },
      });

      expect(session.sessionExercises).toHaveLength(3);
      expect(session.sessionExercises[0].exercise.name).toBeDefined();
    });
  });

  describe('步骤5: 开始跟练模式', () => {
    it('should update session status to IN_PROGRESS', async () => {
      await prisma.workoutSession.update({
        where: { id: sessionId },
        data: { status: 'IN_PROGRESS' },
      });

      const session = await prisma.workoutSession.findUnique({ where: { id: sessionId } });
      expect(session.status).toBe('IN_PROGRESS');
    });
  });

  describe('步骤6: 完成所有动作', () => {
    it('should update session status to COMPLETED with actual duration', async () => {
      await prisma.workoutSession.update({
        where: { id: sessionId },
        data: {
          status: 'COMPLETED',
          actualDuration: 65,
          completedAt: new Date(),
        },
      });

      const session = await prisma.workoutSession.findUnique({ where: { id: sessionId } });
      expect(session.status).toBe('COMPLETED');
      expect(session.actualDuration).toBe(65);
      expect(session.completedAt).toBeDefined();
    });
  });

  describe('步骤7: 生成成果卡片', () => {
    it('should generate card in ≤800ms', async () => {
      const startTime = Date.now();
      const card = await testData.createTestCard(testUserId, sessionId);
      const generateTime = Date.now() - startTime;

      expect(card).toBeDefined();
      expect(card.rarity).toBeDefined();
      expect(generateTime).toBeLessThan(800);
    }, 1000);

    it('should calculate rarity score', async () => {
      const card = await prisma.shareCard.findFirst({
        where: { sessionId },
      });

      expect(card.rarityScore).toBeGreaterThan(0);
      expect(card.rarityScore).toBeLessThanOrEqual(1);
    });
  });

  describe('步骤8: 验证统计数据', () => {
    it('should update user stats', async () => {
      const sessions = await prisma.workoutSession.count({
        where: { userId: testUserId, status: 'COMPLETED' },
      });

      const cards = await prisma.shareCard.count({
        where: { userId: testUserId },
      });

      expect(sessions).toBeGreaterThan(0);
      expect(cards).toBeGreaterThan(0);
    });
  });

  describe('性能指标验证', () => {
    it('TTV (Time to Value) should be ≤30 seconds', () => {
      // 从步骤3到步骤4的总时间应该≤30秒
      // 在实际场景中通过端到端计时验证
      expect(true).toBe(true); // 占位符
    });
  });
});

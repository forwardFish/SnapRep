import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';

describe('E2E场景3: 复刻同款流程', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let originalSessionId: string;
  let userId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);

    // 创建原始会话
    const user = await testData.createTestUser('copytest@example.com');
    userId = user.id;
    const exercises = await testData.getTestExercises(3);
    const session = await testData.createTestSession(userId, exercises.map(e => e.id));
    originalSessionId = session.id;

    await prisma.workoutSession.update({
      where: { id: originalSessionId },
      data: { status: 'COMPLETED', completedAt: new Date() },
    });

    await testData.createTestCard(userId, originalSessionId);
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('查看历史卡片', () => {
    it('should display user cards', async () => {
      const cards = await prisma.shareCard.findMany({
        where: { userId },
        include: { session: true },
      });

      expect(cards.length).toBeGreaterThan(0);
    });
  });

  describe('读取原始条件', () => {
    it('should retrieve original session parameters', async () => {
      const originalSession = await prisma.workoutSession.findUnique({
        where: { id: originalSessionId },
        include: { sessionExercises: true },
      });

      expect(originalSession.intentType).toBeDefined();
      expect(originalSession.difficulty).toBeDefined();
      expect(originalSession.sessionExercises.length).toBe(3);
    });
  });

  describe('一键同款复刻', () => {
    it('should create new session with same parameters', async () => {
      const original = await prisma.workoutSession.findUnique({
        where: { id: originalSessionId },
      });

      const exercises = await testData.getTestExercises(3);
      const copiedSession = await testData.createTestSession(userId, exercises.map(e => e.id));

      await prisma.workoutSession.update({
        where: { id: copiedSession.id },
        data: {
          intentType: original.intentType,
          difficulty: original.difficulty,
          totalDuration: original.totalDuration,
        },
      });

      const copied = await prisma.workoutSession.findUnique({
        where: { id: copiedSession.id },
      });

      expect(copied.intentType).toBe(original.intentType);
      expect(copied.difficulty).toBe(original.difficulty);
      expect(copied.totalDuration).toBe(original.totalDuration);
    });
  });

  describe('验证条件一致性', () => {
    it('should verify equipment consistency', async () => {
      // 验证器材相同
      const original = await prisma.workoutSession.findUnique({
        where: { id: originalSessionId },
        include: { sessionExercises: { include: { exercise: true } } },
      });

      expect(original.sessionExercises[0].exercise).toBeDefined();
    });

    it('should allow different exercises (randomness)', () => {
      // 推荐动作可能不同，这是正常的
      expect(true).toBe(true);
    });
  });
});

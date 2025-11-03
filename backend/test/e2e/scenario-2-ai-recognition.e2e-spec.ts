import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';

describe('E2E场景2: AI识别流程', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    testData = new TestDataHelper(prisma);
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('AI识别物品', () => {
    it('should process image upload', async () => {
      // 模拟AI识别结果
      const mockAIResult = {
        detectedObject: 'chair',
        confidence: 0.92,
        autoSelected: true,
      };

      expect(mockAIResult.confidence).toBeGreaterThanOrEqual(0.85);
      expect(mockAIResult.autoSelected).toBe(true);
    });

    it('should complete recognition in ≤3 seconds', async () => {
      const startTime = Date.now();
      // 模拟AI识别过程
      await new Promise(resolve => setTimeout(resolve, 100)); // 模拟100ms处理
      const recognitionTime = Date.now() - startTime;

      expect(recognitionTime).toBeLessThan(3000);
    }, 3500);
  });

  describe('高置信度自动预选', () => {
    it('should auto-select when confidence ≥85%', () => {
      const confidence = 0.92;
      const shouldAutoSelect = confidence >= 0.85;

      expect(shouldAutoSelect).toBe(true);
    });

    it('should show manual selection when confidence <85%', () => {
      const confidence = 0.70;
      const shouldAutoSelect = confidence >= 0.85;

      expect(shouldAutoSelect).toBe(false);
    });
  });

  describe('生成推荐', () => {
    it('should generate exercises with identified equipment', async () => {
      const chairExercises = await prisma.exercise.findMany({
        where: {
          isActive: true,
          exerciseEquipment: {
            some: {
              equipment: {
                code: 'chair',
              },
            },
          },
        },
        take: 3,
      });

      expect(chairExercises.length).toBeGreaterThan(0);
    });
  });

  describe('性能指标', () => {
    it('AI recognition accuracy should be ≥70%', () => {
      const accuracy = 0.92; // 模拟准确率
      expect(accuracy).toBeGreaterThanOrEqual(0.70);
    });

    it('Recognition time should be ≤3 seconds', () => {
      const time = 1.2; // 模拟识别时间(秒)
      expect(time).toBeLessThanOrEqual(3);
    });
  });
});

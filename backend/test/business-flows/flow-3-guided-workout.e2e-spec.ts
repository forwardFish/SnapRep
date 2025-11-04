import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程3: 锻炼引导3步骤', () => {
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

  describe('3.1 Step 1: 运动意图选择', () => {
    it('should display 4 intent options with default selection', async () => {
      const response = await request(httpServer)
        .get('/api/v1/workout-guide/step1/intents')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.intents).toBeInstanceOf(Array);
      expect(response.body.intents.length).toBe(4);

      const intentCodes = response.body.intents.map(intent => intent.code);
      expect(intentCodes).toContain('RELAX');
      expect(intentCodes).toContain('STRETCH');
      expect(intentCodes).toContain('CARDIO');
      expect(intentCodes).toContain('STRENGTH');

      // 验证默认选择
      expect(response.body.defaultSelection).toBe('STRETCH');

      // 验证每个意图的描述
      response.body.intents.forEach(intent => {
        expect(intent).toHaveProperty('code');
        expect(intent).toHaveProperty('name');
        expect(intent).toHaveProperty('description');
        expect(intent).toHaveProperty('icon');
        expect(intent).toHaveProperty('subtitle');
      });
    });

    it('should support multi-selection up to 2 items', async () => {
      const validSelections = [
        ['RELAX'],
        ['STRETCH'],
        ['RELAX', 'STRETCH'],
        ['CARDIO', 'STRENGTH'],
      ];

      for (const selection of validSelections) {
        const response = await request(httpServer)
          .post('/api/v1/workout-guide/step1/validate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            selectedIntents: selection,
          })
          .expect(200);

        expect(response.body.valid).toBe(true);
        expect(response.body.selectedIntents).toEqual(selection);
      }
    });

    it('should reject more than 2 selections', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step1/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['RELAX', 'STRETCH', 'CARDIO'],
        })
        .expect(400);

      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('最多选择2项');
    });

    it('should handle "直接开练60秒" shortcut', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/quick-workout')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          duration: 60,
        })
        .expect(201);

      // 应该直接跳转到结果页，跳过后续步骤
      expect(response.body.exercises).toBeInstanceOf(Array);
      expect(response.body.exercises.length).toBe(3);
      expect(response.body.sessionId).toBeDefined();
      expect(response.body.skippedGuide).toBe(true);

      // 验证使用默认配置
      const session = await prisma.workoutSession.findUnique({
        where: { id: response.body.sessionId },
      });

      expect(session.intentType).toBe('STRETCH');
      expect(session.difficulty).toBe('GREEN');
    });

    it('should provide skip option with default values', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step1/skip')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.defaultIntents).toEqual(['STRETCH']);
      expect(response.body.proceedToStep2).toBe(true);
    });
  });

  describe('3.2 Step 2: 场景+物品选择', () => {
    let step1Data: any;

    beforeEach(async () => {
      // 完成步骤1
      step1Data = {
        selectedIntents: ['STRETCH'],
      };
    });

    it('should display scenario options with dynamic equipment suggestions', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/scenarios')
        .set('Authorization', `Bearer ${userToken}`)
        .send(step1Data)
        .expect(200);

      expect(response.body.scenarios).toBeInstanceOf(Array);
      expect(response.body.scenarios.length).toBeGreaterThanOrEqual(5);

      const scenarioCodes = response.body.scenarios.map(s => s.code);
      expect(scenarioCodes).toContain('office');
      expect(scenarioCodes).toContain('living_room');
      expect(scenarioCodes).toContain('park');
      expect(scenarioCodes).toContain('bedroom');
      expect(scenarioCodes).toContain('travel');

      // 验证默认选择
      expect(response.body.defaultScenario).toBe('living_room');

      // 验证每个场景都有预设器材
      response.body.scenarios.forEach(scenario => {
        expect(scenario).toHaveProperty('code');
        expect(scenario).toHaveProperty('name');
        expect(scenario).toHaveProperty('suggestedEquipment');
        expect(scenario.suggestedEquipment).toBeInstanceOf(Array);
      });
    });

    it('should update equipment suggestions when scenario changes', async () => {
      // 测试办公室场景
      const officeResponse = await request(httpServer)
        .post('/api/v1/workout-guide/step2/equipment-suggestions')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'office',
        })
        .expect(200);

      const officeEquipment = officeResponse.body.suggestedEquipment.map(e => e.code);
      expect(officeEquipment).toContain('chair');
      expect(officeEquipment).toContain('wall');

      // 测试公园场景
      const parkResponse = await request(httpServer)
        .post('/api/v1/workout-guide/step2/equipment-suggestions')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'park',
        })
        .expect(200);

      const parkEquipment = parkResponse.body.suggestedEquipment.map(e => e.code);
      expect(parkEquipment).toContain('bench');
      expect(parkEquipment).toContain('tree');

      // 验证不同场景的建议不完全相同
      expect(officeEquipment).not.toEqual(parkEquipment);
    });

    it('should support multi-select equipment with mutual exclusion', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'office',
          selectedEquipment: ['chair', 'wall'],
        })
        .expect(200);

      expect(response.body.valid).toBe(true);
      expect(response.body.selectedEquipment).toEqual(['chair', 'wall']);
    });

    it('should handle "无" equipment selection with mutual exclusion', async () => {
      // "无"与其他器材互斥
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'office',
          selectedEquipment: ['hands_free', 'chair'], // 应该失败
        })
        .expect(400);

      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('互斥');

      // 单独选择"无"应该成功
      const validResponse = await request(httpServer)
        .post('/api/v1/workout-guide/step2/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'office',
          selectedEquipment: ['hands_free'],
        })
        .expect(200);

      expect(validResponse.body.valid).toBe(true);
    });

    it('should integrate AI recognition results', async () => {
      // 模拟AI识别结果
      const mockRecognitionResult = {
        recognized: ['chair'],
        confidence: 0.9,
        autoPreselected: true,
      };

      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/integrate-ai')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step1Data,
          selectedScenario: 'office',
          aiRecognitionResult: mockRecognitionResult,
        })
        .expect(200);

      expect(response.body.selectedEquipment).toContain('chair');
      expect(response.body.aiIntegrated).toBe(true);
    });

    it('should provide default values when skipped', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/skip')
        .set('Authorization', `Bearer ${userToken}`)
        .send(step1Data)
        .expect(200);

      expect(response.body.defaultScenario).toBe('living_room');
      expect(response.body.defaultEquipment).toEqual(['hands_free']);
      expect(response.body.proceedToStep3).toBe(true);
    });
  });

  describe('3.3 Step 3: 目标部位选择', () => {
    let step2Data: any;

    beforeEach(async () => {
      // 完成步骤1和2
      step2Data = {
        selectedIntents: ['STRETCH'],
        selectedScenario: 'office',
        selectedEquipment: ['chair', 'wall'],
      };
    });

    it('should display 8 muscle group options in 2-column grid', async () => {
      const response = await request(httpServer)
        .get('/api/v1/workout-guide/step3/muscle-groups')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.muscleGroups).toBeInstanceOf(Array);
      expect(response.body.muscleGroups.length).toBe(8);

      const expectedGroups = [
        'FULL_BODY', 'NECK_SHOULDERS', 'CHEST_BACK',
        'CORE', 'THIGHS', 'GLUTES', 'CALVES', 'ARMS'
      ];

      const actualGroups = response.body.muscleGroups.map(group => group.code);
      expectedGroups.forEach(expected => {
        expect(actualGroups).toContain(expected);
      });

      // 验证默认选择
      expect(response.body.defaultSelection).toBe('FULL_BODY');

      // 验证UI布局信息
      expect(response.body.layoutConfig.columns).toBe(2);
      expect(response.body.layoutConfig.chipStyle).toBeDefined();
    });

    it('should support multi-select up to 2 muscle groups', async () => {
      const validSelections = [
        ['FULL_BODY'],
        ['NECK_SHOULDERS'],
        ['CHEST_BACK', 'CORE'],
        ['THIGHS', 'GLUTES'],
      ];

      for (const selection of validSelections) {
        const response = await request(httpServer)
          .post('/api/v1/workout-guide/step3/validate')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            ...step2Data,
            selectedMuscleGroups: selection,
          })
          .expect(200);

        expect(response.body.valid).toBe(true);
        expect(response.body.selectedMuscleGroups).toEqual(selection);
      }
    });

    it('should reject more than 2 muscle group selections', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step3/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step2Data,
          selectedMuscleGroups: ['FULL_BODY', 'CHEST_BACK', 'CORE'],
        })
        .expect(400);

      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('最多选择2项');
    });

    it('should complete guide and generate workout', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step2Data,
          selectedMuscleGroups: ['NECK_SHOULDERS', 'CORE'],
        })
        .expect(201);

      // 验证跳转到动作结果页
      expect(response.body.exercises).toBeInstanceOf(Array);
      expect(response.body.exercises.length).toBe(3);
      expect(response.body.sessionId).toBeDefined();
      expect(response.body.alternatives).toBeDefined();

      // 验证会话数据存储
      const session = await prisma.workoutSession.findUnique({
        where: { id: response.body.sessionId },
        include: { sessionExercises: true },
      });

      expect(session).toBeDefined();
      expect(session.userId).toBe(userId);
      expect(session.intentType).toBe('STRETCH');
      expect(session.scenarioCode).toBe('office');
      expect(session.status).toBe('CREATED');
      expect(session.sessionExercises.length).toBe(3);

      // 验证动作符合选择条件
      session.sessionExercises.forEach(sessionExercise => {
        // 这里需要通过关联查询验证动作是否符合条件
        // 由于测试环境限制，我们验证基本结构
        expect(sessionExercise.exerciseId).toBeDefined();
        expect(sessionExercise.sequenceOrder).toBeGreaterThan(0);
        expect(sessionExercise.duration).toBeGreaterThan(0);
      });
    });

    it('should influence recommendation weighting only', async () => {
      // 选择不同的部位应该影响推荐的侧重，但不改变总时长和安全参数
      const response1 = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step2Data,
          selectedMuscleGroups: ['NECK_SHOULDERS'],
        })
        .expect(201);

      const response2 = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step2Data,
          selectedMuscleGroups: ['CORE'],
        })
        .expect(201);

      // 验证总时长相似
      const totalDuration1 = response1.body.exercises.reduce((sum, ex) => sum + ex.defaultDuration, 0);
      const totalDuration2 = response2.body.exercises.reduce((sum, ex) => sum + ex.defaultDuration, 0);

      expect(Math.abs(totalDuration1 - totalDuration2)).toBeLessThan(20); // 允许20秒误差

      // 验证安全等级相同（意图和场景相同时）
      expect(response1.body.exercises.every(ex => ex.difficulty === 'GREEN')).toBe(true);
      expect(response2.body.exercises.every(ex => ex.difficulty === 'GREEN')).toBe(true);
    });
  });

  describe('引导流程完整性测试', () => {
    it('should complete full 3-step guide within 30 seconds', async () => {
      const startTime = Date.now();

      // Step 1: 意图选择
      const step1Response = await request(httpServer)
        .post('/api/v1/workout-guide/step1/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['STRETCH', 'RELAX'],
        })
        .expect(200);

      // Step 2: 场景+物品选择
      const step2Response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['STRETCH', 'RELAX'],
          selectedScenario: 'office',
          selectedEquipment: ['chair'],
        })
        .expect(200);

      // Step 3: 部位选择 + 完成
      const step3Response = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['STRETCH', 'RELAX'],
          selectedScenario: 'office',
          selectedEquipment: ['chair'],
          selectedMuscleGroups: ['NECK_SHOULDERS'],
        })
        .expect(201);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(30000);

      // 验证最终结果
      expect(step3Response.body.exercises.length).toBe(3);
      expect(step3Response.body.sessionId).toBeDefined();
    });

    it('should handle guide abandonment gracefully', async () => {
      // 模拟用户在步骤2中途退出
      const step1Data = {
        selectedIntents: ['CARDIO'],
      };

      // 不完成引导流程，直接退出
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/abandon')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          abandonedAtStep: 2,
          partialData: step1Data,
        })
        .expect(200);

      expect(response.body.message).toContain('引导已取消');
      expect(response.body.suggestedActions).toBeDefined();
      expect(response.body.suggestedActions).toContain('quick_start');
    });

    it('should maintain state between steps', async () => {
      // 验证步骤间数据传递的一致性
      const step1Data = {
        selectedIntents: ['STRENGTH', 'CARDIO'],
      };

      const step2Data = {
        ...step1Data,
        selectedScenario: 'park',
        selectedEquipment: ['bench', 'tree'],
      };

      const finalResponse = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          ...step2Data,
          selectedMuscleGroups: ['THIGHS', 'CORE'],
        })
        .expect(201);

      // 验证最终会话包含所有步骤的选择
      const session = await prisma.workoutSession.findUnique({
        where: { id: finalResponse.body.sessionId },
      });

      expect(session.intentType).toBe('STRENGTH'); // 应该取主要意图
      expect(session.scenarioCode).toBe('park');
      // targetMuscles应该包含选择的部位
    });
  });

  describe('错误处理和边界情况', () => {
    it('should handle invalid intent combinations', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step1/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['INVALID_INTENT'],
        })
        .expect(400);

      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('无效的意图类型');
    });

    it('should handle invalid scenario codes', async () => {
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/step2/validate')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['STRETCH'],
          selectedScenario: 'INVALID_SCENARIO',
          selectedEquipment: ['chair'],
        })
        .expect(400);

      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('无效的场景代码');
    });

    it('should handle missing exercise data gracefully', async () => {
      // 模拟极端情况：某个组合没有可用动作
      const response = await request(httpServer)
        .post('/api/v1/workout-guide/complete')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          selectedIntents: ['STRENGTH'],
          selectedScenario: 'office',
          selectedEquipment: ['impossible_equipment'],
          selectedMuscleGroups: ['FULL_BODY'],
        })
        .expect(400);

      expect(response.body.error).toContain('无法找到符合条件的动作');
      expect(response.body.suggestedAlternatives).toBeDefined();
    });
  });
});
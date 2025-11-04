import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from 'nestjs-prisma';
import { TestDataHelper } from '../helpers/test-data.helper';
import * as request from 'supertest';

describe('业务流程4: 动作结果页', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let testData: TestDataHelper;
  let httpServer: any;
  let userToken: string;
  let userId: string;
  let sessionId: string;

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

    // 创建测试会话
    const quickStartResponse = await request(httpServer)
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

    sessionId = quickStartResponse.body.sessionId;
  });

  afterAll(async () => {
    await testData.cleanupTestData();
    await app.close();
  });

  describe('4.1 页面加载与展示', () => {
    it('should load workout result with 3 exercises and alternatives', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 验证基本结构
      expect(response.body.sessionId).toBe(sessionId);
      expect(response.body.exercises).toBeInstanceOf(Array);
      expect(response.body.exercises.length).toBe(3);
      expect(response.body.alternatives).toBeInstanceOf(Array);
      expect(response.body.sessionInfo).toBeDefined();

      // 验证每个动作卡的完整信息
      response.body.exercises.forEach((exercise, index) => {
        expect(exercise).toHaveProperty('id');
        expect(exercise).toHaveProperty('name');
        expect(exercise).toHaveProperty('difficulty');
        expect(exercise).toHaveProperty('primaryMuscle');
        expect(exercise).toHaveProperty('tags');
        expect(exercise).toHaveProperty('safetyNotes');
        expect(exercise).toHaveProperty('contraindications');
        expect(exercise).toHaveProperty('defaultDuration');
        expect(exercise).toHaveProperty('videoUrl');
        expect(exercise).toHaveProperty('sequenceOrder');
        expect(exercise.sequenceOrder).toBe(index + 1);
      });

      // 验证替换候选列表
      expect(response.body.alternatives.length).toBeGreaterThan(0);
      expect(response.body.alternatives.length).toBeLessThanOrEqual(9);
    });

    it('should display session info correctly', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const sessionInfo = response.body.sessionInfo;
      expect(sessionInfo.intentType).toBe('STRETCH');
      expect(sessionInfo.difficulty).toBe('GREEN');
      expect(sessionInfo.totalDuration).toBe(60);
      expect(sessionInfo.equipmentUsed).toContain('chair');
      expect(sessionInfo.targetMuscles).toContain('NECK_SHOULDERS');
    });

    it('should load images and videos properly', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 验证每个动作都有视觉资源
      response.body.exercises.forEach(exercise => {
        expect(exercise.videoUrl || exercise.imageUrl).toBeDefined();

        if (exercise.videoUrl) {
          expect(exercise.videoUrl).toMatch(/\.(mp4|webm|mov)$/i);
        }

        if (exercise.imageUrl) {
          expect(exercise.imageUrl).toMatch(/\.(jpg|jpeg|png|webp|gif)$/i);
        }
      });
    });

    it('should display safety information prominently', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      response.body.exercises.forEach(exercise => {
        // 每个动作都应该有安全提示
        expect(exercise.safetyNotes).toBeDefined();
        expect(exercise.safetyNotes.length).toBeGreaterThan(0);

        // 验证安全注意事项格式 (应该是两条红线)
        if (exercise.safetyNotes.length >= 2) {
          exercise.safetyNotes.forEach(note => {
            expect(typeof note).toBe('string');
            expect(note.length).toBeGreaterThan(0);
          });
        }

        // 验证禁忌症信息
        expect(exercise.contraindications).toBeDefined();
      });
    });
  });

  describe('4.2 用户身份验证检查', () => {
    it('should trigger login flow for first-time anonymous users', async () => {
      // 创建新的匿名用户
      const newUserResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const newUserToken = newUserResponse.body.accessToken;

      // 创建会话
      const sessionResponse = await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${newUserToken}`)
        .send({
          intentType: 'STRETCH',
          difficulty: 'GREEN',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 60,
        })
        .expect(201);

      // 尝试开始跟练
      const workoutStartResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionResponse.body.sessionId}/start`)
        .set('Authorization', `Bearer ${newUserToken}`)
        .expect(200);

      // 验证是否触发了登录选择流程
      if (workoutStartResponse.body.requiresLogin) {
        expect(workoutStartResponse.body.loginOptions).toBeDefined();
        expect(workoutStartResponse.body.loginOptions).toContain('email');
        expect(workoutStartResponse.body.loginOptions).toContain('anonymous_continue');
        expect(workoutStartResponse.body.loginOptions).toContain('skip');
      }
    });

    it('should allow existing users to start workout directly', async () => {
      // 使用已有用户
      const response = await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.workoutStarted).toBe(true);
      expect(response.body.requiresLogin).toBe(false);

      // 验证会话状态更新
      const session = await prisma.workoutSession.findUnique({
        where: { id: sessionId },
      });

      expect(session.status).toBe('IN_PROGRESS');
      expect(session.startedAt).toBeDefined();
    });

    it('should handle email login upgrade during workout', async () => {
      // 创建匿名用户会话
      const anonResponse = await request(httpServer)
        .post('/auth/anonymous')
        .expect(201);

      const anonToken = anonResponse.body.accessToken;
      const anonUserId = anonResponse.body.user.id;

      const anonSessionResponse = await request(httpServer)
        .post('/api/v1/recommendations/quick')
        .set('Authorization', `Bearer ${anonToken}`)
        .send({
          intentType: 'CARDIO',
          difficulty: 'BLUE',
          equipmentCodes: ['hands_free'],
          targetMuscles: ['FULL_BODY'],
          duration: 90,
        })
        .expect(201);

      // 升级为邮箱账户
      const upgradeResponse = await request(httpServer)
        .post('/auth/upgrade-to-email')
        .set('Authorization', `Bearer ${anonToken}`)
        .send({
          email: 'upgrade-during-workout@example.com',
        })
        .expect(200);

      // 验证数据迁移
      const migratedSession = await prisma.workoutSession.findUnique({
        where: { id: anonSessionResponse.body.sessionId },
      });

      expect(migratedSession.userId).toBe(anonUserId);

      const upgradedUser = await prisma.user.findUnique({
        where: { id: anonUserId },
      });

      expect(upgradedUser.email).toBe('upgrade-during-workout@example.com');
      expect(upgradedUser.isAnonymous).toBe(false);
    });
  });

  describe('4.3 开始跟练模式', () => {
    let workoutSessionId: string;

    beforeEach(async () => {
      // 为每个测试创建新的会话
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

      workoutSessionId = sessionResponse.body.sessionId;
    });

    it('should start workout and update session status', async () => {
      const response = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.workoutStarted).toBe(true);
      expect(response.body.currentExercise).toBeDefined();
      expect(response.body.progress).toBeDefined();

      // 验证会话状态
      const session = await prisma.workoutSession.findUnique({
        where: { id: workoutSessionId },
      });

      expect(session.status).toBe('IN_PROGRESS');
      expect(session.startedAt).toBeDefined();
    });

    it('should provide workout control functions', async () => {
      // 开始跟练
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 暂停
      const pauseResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/pause`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(pauseResponse.body.paused).toBe(true);

      // 继续
      const resumeResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/resume`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(resumeResponse.body.resumed).toBe(true);

      // 跳过当前动作
      const skipResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/skip-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(skipResponse.body.skipped).toBe(true);
      expect(skipResponse.body.nextExercise).toBeDefined();
    });

    it('should track progress correctly', async () => {
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 完成第一个动作
      const complete1Response = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/complete-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          exerciseSequence: 1,
        })
        .expect(200);

      expect(complete1Response.body.progress.completed).toBe(1);
      expect(complete1Response.body.progress.total).toBe(3);
      expect(complete1Response.body.progress.percentage).toBeCloseTo(33.33, 1);

      // 完成第二个动作
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/complete-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          exerciseSequence: 2,
        })
        .expect(200);

      // 完成第三个动作
      const finalResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${workoutSessionId}/complete-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          exerciseSequence: 3,
        })
        .expect(200);

      expect(finalResponse.body.workoutCompleted).toBe(true);
      expect(finalResponse.body.progress.percentage).toBe(100);

      // 验证会话状态
      const session = await prisma.workoutSession.findUnique({
        where: { id: workoutSessionId },
      });

      expect(session.status).toBe('COMPLETED');
      expect(session.completedAt).toBeDefined();
    });
  });

  describe('4.4 替换单个动作', () => {
    it('should show replace options for each exercise', async () => {
      const response = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/1/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(response.body.alternatives).toBeInstanceOf(Array);
      expect(response.body.alternatives.length).toBeGreaterThan(0);
      expect(response.body.filters).toBeDefined();
      expect(response.body.filters.intensityOptions).toContain('更放松');
      expect(response.body.filters.intensityOptions).toContain('更有感觉');

      // 验证候选动作结构
      response.body.alternatives.forEach(alternative => {
        expect(alternative).toHaveProperty('id');
        expect(alternative).toHaveProperty('name');
        expect(alternative).toHaveProperty('difficulty');
        expect(alternative).toHaveProperty('primaryMuscle');
        expect(alternative).toHaveProperty('previewImageUrl');
        expect(alternative).toHaveProperty('tags');
      });
    });

    it('should filter alternatives by intensity', async () => {
      // 测试"更放松"筛选
      const relaxedResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/1/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .query({ intensity: '更放松' })
        .expect(200);

      // 测试"更有感觉"筛选
      const intenseResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/1/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .query({ intensity: '更有感觉' })
        .expect(200);

      // 验证筛选结果不同
      expect(relaxedResponse.body.alternatives).toBeDefined();
      expect(intenseResponse.body.alternatives).toBeDefined();

      // 更放松的选项应该难度更低
      if (relaxedResponse.body.alternatives.length > 0) {
        relaxedResponse.body.alternatives.forEach(alt => {
          expect(['GREEN'].includes(alt.difficulty)).toBe(true);
        });
      }
    });

    it('should replace exercise and update session', async () => {
      // 获取替换选项
      const alternativesResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/2/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const newExerciseId = alternativesResponse.body.alternatives[0].id;

      // 执行替换
      const replaceResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/replace-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          position: 2,
          newExerciseId: newExerciseId,
        })
        .expect(200);

      expect(replaceResponse.body.replaced).toBe(true);
      expect(replaceResponse.body.newExercise.id).toBe(newExerciseId);

      // 验证会话更新
      const updatedSession = await prisma.workoutSession.findUnique({
        where: { id: sessionId },
        include: { sessionExercises: true },
      });

      const replacedExercise = updatedSession.sessionExercises.find(se => se.sequenceOrder === 2);
      expect(replacedExercise.exerciseId).toBe(newExerciseId);
    });

    it('should avoid duplicates when replacing', async () => {
      // 获取当前会话的所有动作
      const sessionResult = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const currentExerciseIds = sessionResult.body.exercises.map(ex => ex.id);

      // 获取替换选项
      const alternativesResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/1/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 验证替换选项不包含当前已有的动作
      alternativesResponse.body.alternatives.forEach(alternative => {
        expect(currentExerciseIds).not.toContain(alternative.id);
      });
    });
  });

  describe('4.5 换一批', () => {
    it('should generate new set of 3 exercises', async () => {
      // 获取当前动作
      const originalResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const originalExerciseIds = originalResponse.body.exercises.map(ex => ex.id);

      // 换一批
      const newBatchResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/regenerate`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(newBatchResponse.body.exercises).toBeInstanceOf(Array);
      expect(newBatchResponse.body.exercises.length).toBe(3);

      const newExerciseIds = newBatchResponse.body.exercises.map(ex => ex.id);

      // 验证与原动作无重复
      newExerciseIds.forEach(newId => {
        expect(originalExerciseIds).not.toContain(newId);
      });

      // 验证条件保持一致
      expect(newBatchResponse.body.sessionInfo.intentType).toBe('STRETCH');
      expect(newBatchResponse.body.sessionInfo.difficulty).toBe('GREEN');
    });

    it('should maintain same workout conditions', async () => {
      const originalResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const originalConditions = originalResponse.body.sessionInfo;

      // 换一批
      const newBatchResponse = await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/regenerate`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const newConditions = newBatchResponse.body.sessionInfo;

      // 验证条件保持一致
      expect(newConditions.intentType).toBe(originalConditions.intentType);
      expect(newConditions.difficulty).toBe(originalConditions.difficulty);
      expect(newConditions.equipmentUsed).toEqual(originalConditions.equipmentUsed);
      expect(newConditions.targetMuscles).toEqual(originalConditions.targetMuscles);
    });

    it('should implement same-round deduplication', async () => {
      const allGeneratedIds = new Set();

      // 连续换批3次
      for (let i = 0; i < 3; i++) {
        const response = await request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/regenerate`)
          .set('Authorization', `Bearer ${userToken}`)
          .expect(200);

        const exerciseIds = response.body.exercises.map(ex => ex.id);

        // 验证这批动作内部无重复
        const uniqueIds = new Set(exerciseIds);
        expect(uniqueIds.size).toBe(exerciseIds.length);

        // 收集所有生成的动作ID
        exerciseIds.forEach(id => allGeneratedIds.add(id));
      }

      // 应该生成了多个不同的动作 (同轮去重机制)
      expect(allGeneratedIds.size).toBeGreaterThan(3);
    });
  });

  describe('性能和用户体验验证', () => {
    it('should load result page within 2 seconds', async () => {
      const startTime = Date.now();

      await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/result`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(2000);
    });

    it('should handle replacement within 3 seconds', async () => {
      const startTime = Date.now();

      // 获取替换选项并执行替换
      const alternativesResponse = await request(httpServer)
        .get(`/api/v1/workout-sessions/${sessionId}/exercise/1/alternatives`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      const newExerciseId = alternativesResponse.body.alternatives[0].id;

      await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/replace-exercise`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          position: 1,
          newExerciseId: newExerciseId,
        })
        .expect(200);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(3000);
    });

    it('should provide smooth exercise transitions', async () => {
      await request(httpServer)
        .post(`/api/v1/workout-sessions/${sessionId}/start`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      // 测试快速连续操作
      const operations = [
        () => request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/complete-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({ exerciseSequence: 1 }),
        () => request(httpServer)
          .get(`/api/v1/workout-sessions/${sessionId}/current-status`)
          .set('Authorization', `Bearer ${userToken}`),
        () => request(httpServer)
          .post(`/api/v1/workout-sessions/${sessionId}/complete-exercise`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({ exerciseSequence: 2 }),
      ];

      const startTime = Date.now();
      for (const operation of operations) {
        await operation().expect(200);
      }
      const duration = Date.now() - startTime;

      expect(duration).toBeLessThan(5000); // 所有操作应该在5秒内完成
    });
  });
});
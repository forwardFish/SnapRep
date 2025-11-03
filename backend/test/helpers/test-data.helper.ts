import { PrismaClient } from '@prisma/client';

export class TestDataHelper {
  private prisma: PrismaClient;

  constructor(prisma: PrismaClient) {
    this.prisma = prisma;
  }

  /**
   * 创建测试用户
   */
  async createTestUser(email: string = 'test@example.com', name?: string) {
    const userId = require('crypto').randomUUID();
    return await this.prisma.user.create({
      data: {
        id: userId,
        email,
        name: name || 'Test User',
      },
    });
  }

  /**
   * 创建测试训练会话
   */
  async createTestSession(userId: string, exerciseIds: string[]) {
    return await this.prisma.workoutSession.create({
      data: {
        userId,
        intentType: 'STRETCH',
        totalDuration: 60,
        difficulty: 'GREEN',
        status: 'PENDING',
        sessionExercises: {
          create: exerciseIds.map((exId, index) => ({
            exerciseId: exId,
            sequenceOrder: index + 1,
            duration: 20,
            sets: 1,
          })),
        },
      },
      include: {
        sessionExercises: true,
      },
    });
  }

  /**
   * 获取测试动作
   */
  async getTestExercises(count: number = 3) {
    return await this.prisma.exercise.findMany({
      where: { isActive: true },
      take: count,
    });
  }

  /**
   * 创建测试卡片
   */
  async createTestCard(userId: string, sessionId: string) {
    return await this.prisma.shareCard.create({
      data: {
        userId,
        sessionId,
        cardImageUrl: '/test/card.jpg',
        rarity: 'COMMON',
        rarityScore: 0.5,
        equipmentSeries: 'chair',
        cardTemplate: 'classic',
        cardData: {},
      },
    });
  }

  /**
   * 清理测试数据
   */
  async cleanupTestData() {
    await this.prisma.shareCard.deleteMany({
      where: { cardImageUrl: { startsWith: '/test/' } },
    });
    await this.prisma.sessionExercise.deleteMany({});
    await this.prisma.workoutSession.deleteMany({
      where: { user: { email: { contains: 'test' } } },
    });
    await this.prisma.user.deleteMany({
      where: { email: { contains: 'test' } },
    });
  }
}

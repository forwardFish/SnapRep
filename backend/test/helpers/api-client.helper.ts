import * as request from 'supertest';
import { INestApplication } from '@nestjs/common';

export class ApiClientHelper {
  private app: INestApplication;
  private authToken: string;

  constructor(app: INestApplication) {
    this.app = app;
  }

  /**
   * 认证测试用户并获取Token
   */
  async authenticateUser(email: string, password: string) {
    const response = await request(this.app.getHttpServer())
      .post('/auth/login')
      .send({ email, password })
      .expect(200);

    this.authToken = response.body.accessToken;
    return this.authToken;
  }

  /**
   * 发送认证请求
   */
  async makeAuthenticatedRequest(method: 'get' | 'post' | 'patch' | 'delete', url: string, data?: any) {
    const req = request(this.app.getHttpServer())[method](url)
      .set('Authorization', `Bearer ${this.authToken}`);

    if (data) {
      req.send(data);
    }

    return req;
  }

  /**
   * 断言成功响应
   */
  expectSuccess(response: request.Response, expectedStatus: number = 200) {
    expect(response.status).toBe(expectedStatus);
    expect(response.body.success).toBe(true);
  }

  /**
   * 断言错误响应
   */
  expectError(response: request.Response, expectedStatus: number, expectedMessage?: string) {
    expect(response.status).toBe(expectedStatus);
    if (expectedMessage) {
      expect(response.body.message).toContain(expectedMessage);
    }
  }

  /**
   * 快速推荐API调用
   */
  async quickRecommendation(params: {
    intent?: string;
    equipment?: string[];
    duration?: number;
  }) {
    return await this.makeAuthenticatedRequest('post', '/api/v1/recommendations/quick', params);
  }

  /**
   * 创建训练会话
   */
  async createWorkoutSession(data: any) {
    return await this.makeAuthenticatedRequest('post', '/api/v1/workout-sessions', data);
  }

  /**
   * 生成分享卡片
   */
  async generateCard(sessionId: string) {
    return await this.makeAuthenticatedRequest('post', '/api/v1/cards/generate', {
      sessionId,
      cardStyle: 'classic',
    });
  }
}

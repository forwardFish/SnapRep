import { Injectable, Logger } from '@nestjs/common';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

/**
 * Scenario DAO 类
 * TEMPORARY IMPLEMENTATION: Using mock data until Prisma client is working
 */
@Injectable()
export class ScenariosDao {
  private readonly logger = new Logger(ScenariosDao.name);

  // Mock data until Prisma is working
  private mockScenarios = [
    {
      id: 'scenario-001',
      code: 'office',
      name: 'Office',
      iconUrl: '/icons/office.svg',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'scenario-002',
      code: 'home',
      name: 'Home',
      iconUrl: '/icons/home.svg',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'scenario-003',
      code: 'gym',
      name: 'Gym',
      iconUrl: '/icons/gym.svg',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'scenario-004',
      code: 'park',
      name: 'Park',
      iconUrl: '/icons/park.svg',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  constructor() {
    this.logger.log('ScenariosDao initialized (temporary mode without Prisma)');
  }

  /**
   * 根据ID查找场景
   * @param id 场景ID
   * @param includeInactive 是否包含非活跃场景
   * @returns 场景实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const scenario = this.mockScenarios.find(item => item.id === id);

      if (!scenario) {
        return null;
      }

      // 检查是否为活跃场景
      if (!includeInactive && !scenario.isActive) {
        return null;
      }

      return scenario;
    } catch (error) {
      this.logger.error(`根据ID查找场景失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { scenarioId: id });
    }
  }

  /**
   * 根据代码查找场景
   * @param code 场景代码
   * @param includeInactive 是否包含非活跃场景
   * @returns 场景实体或null
   */
  async findByCode(code: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const scenario = this.mockScenarios.find(item => item.code === code);

      if (!scenario) {
        return null;
      }

      if (!includeInactive && !scenario.isActive) {
        return null;
      }

      return scenario;
    } catch (error) {
      this.logger.error(`根据代码查找场景失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { scenarioCode: code });
    }
  }

  /**
   * 获取活跃场景列表
   * @param includeRelations 是否包含关联数据
   * @returns 活跃场景列表
   */
  async findActiveScenarios(includeRelations: boolean = false): Promise<any[]> {
    try {
      return this.mockScenarios.filter(item => item.isActive);
    } catch (error) {
      this.logger.error(`获取活跃场景列表失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.LIST_FAILED, error);
    }
  }

  /**
   * 分页获取场景列表
   * @param page 页码
   * @param pageSize 每页大小
   * @param includeInactive 是否包含非活跃场景
   * @param includeRelations 是否包含关联数据
   * @returns 分页场景列表
   */
  async findScenariosWithPagination(
    page: number,
    pageSize: number,
    includeInactive: boolean = false,
    includeRelations: boolean = false
  ) {
    try {
      let scenarios = this.mockScenarios;

      if (!includeInactive) {
        scenarios = scenarios.filter(item => item.isActive);
      }

      const total = scenarios.length;
      const skip = (page - 1) * pageSize;
      const data = scenarios.slice(skip, skip + pageSize);

      const totalPages = Math.ceil(total / pageSize);
      const hasNextPage = page < totalPages;
      const hasPreviousPage = page > 1;

      return {
        data,
        pagination: {
          total,
          page,
          pageSize,
          totalPages,
          hasNextPage,
          hasPreviousPage,
        }
      };
    } catch (error) {
      this.logger.error(
        `分页获取场景列表失败: page=${page}, pageSize=${pageSize}, error=${error.message}`
      );
      throw new ResponseError(ErrorCodes.SCENARIO.LIST_FAILED, error, { page, pageSize });
    }
  }

  /**
   * 获取活跃场景数量
   * @returns 活跃场景数量
   */
  async getActiveCount(): Promise<number> {
    try {
      return this.mockScenarios.filter(item => item.isActive).length;
    } catch (error) {
      this.logger.error(`获取活跃场景数量失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.COUNT_FAILED, error);
    }
  }

  /**
   * 其他方法的占位符实现（用于避免编译错误）
   */
  async findByConditions(noiseTolerance?: string, spaceRequirement?: string): Promise<any[]> {
    return this.mockScenarios.filter(item => item.isActive);
  }

  async isCodeExists(code: string, excludeId?: string): Promise<boolean> {
    const scenario = this.mockScenarios.find(item =>
      item.code === code && (!excludeId || item.id !== excludeId)
    );
    return !!scenario;
  }

  async createScenario(data: any): Promise<any> {
    const newScenario = {
      id: `scenario-${Date.now()}`,
      ...data,
      isActive: data.isActive ?? true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.mockScenarios.push(newScenario);
    return newScenario;
  }

  async updateScenario(id: string, data: any): Promise<any> {
    const index = this.mockScenarios.findIndex(item => item.id === id);
    if (index === -1) {
      throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND, undefined, { scenarioId: id });
    }

    const updated = {
      ...this.mockScenarios[index],
      ...data,
      updatedAt: new Date(),
    };
    this.mockScenarios[index] = updated;
    return updated;
  }

  async deleteScenario(id: string): Promise<any> {
    const index = this.mockScenarios.findIndex(item => item.id === id);
    if (index === -1) {
      throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND, undefined, { scenarioId: id });
    }

    const deleted = this.mockScenarios[index];
    this.mockScenarios.splice(index, 1);
    return deleted;
  }

  async softDeleteScenario(id: string): Promise<any> {
    return this.updateScenario(id, { isActive: false });
  }

  async batchUpdateStatus(ids: string[], isActive: boolean): Promise<any> {
    let count = 0;
    for (const id of ids) {
      const index = this.mockScenarios.findIndex(item => item.id === id);
      if (index !== -1) {
        this.mockScenarios[index] = {
          ...this.mockScenarios[index],
          isActive,
          updatedAt: new Date(),
        };
        count++;
      }
    }
    return { count };
  }

  async getRelatedExercises(scenarioId: string) {
    // Mock implementation - return empty array for now
    return [];
  }
}
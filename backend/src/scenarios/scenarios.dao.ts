import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

/**
 * Scenario DAO 类
 * 使用 Prisma ORM 进行数据库操作
 */
@Injectable()
export class ScenariosDao extends PrismaBaseDao<any> {
  private readonly logger = new Logger(ScenariosDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    this.logger.log('ScenariosDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.scenario;
  }

  /**
   * 根据ID查找场景
   * @param id 场景ID
   * @param includeInactive 是否包含非活跃场景
   * @returns 场景实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const where: any = { id };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(where);
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
      const where: any = { code };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(where);
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
      const include = includeRelations ? {
        exerciseScenarios: {
          include: {
            exercise: true
          }
        }
      } : undefined;

      return await this.findMany(
        { isActive: true },
        include,
        undefined,
        { name: 'asc' }
      );
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
      const where = includeInactive ? undefined : { isActive: true };

      const include = includeRelations ? {
        exerciseScenarios: {
          include: {
            exercise: true
          }
        }
      } : undefined;

      return await this.findByPage(
        page,
        pageSize,
        where,
        include,
        undefined,
        { name: 'asc' }
      );
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
      return await this.count({ isActive: true });
    } catch (error) {
      this.logger.error(`获取活跃场景数量失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.COUNT_FAILED, error);
    }
  }

  /**
   * 根据条件查找场景
   * @param noiseTolerance 噪音容忍度
   * @param spaceRequirement 空间需求
   * @returns 符合条件的场景列表
   */
  async findByConditions(noiseTolerance?: string, spaceRequirement?: string): Promise<any[]> {
    try {
      const where: any = { isActive: true };

      if (noiseTolerance) {
        where.noiseTolerance = noiseTolerance;
      }

      if (spaceRequirement) {
        where.spaceRequirement = spaceRequirement;
      }

      return await this.findMany(where, undefined, undefined, { name: 'asc' });
    } catch (error) {
      this.logger.error(`根据条件查找场景失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { noiseTolerance, spaceRequirement });
    }
  }

  /**
   * 检查场景代码是否存在
   * @param code 场景代码
   * @param excludeId 排除的场景ID
   * @returns 是否存在
   */
  async isCodeExists(code: string, excludeId?: string): Promise<boolean> {
    try {
      const where: any = { code };
      if (excludeId) {
        where.NOT = { id: excludeId };
      }

      return await this.exists(where);
    } catch (error) {
      this.logger.error(`检查场景代码是否存在失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { scenarioCode: code });
    }
  }

  /**
   * 创建场景
   * @param data 场景数据
   * @returns 创建的场景
   */
  async createScenario(data: any): Promise<any> {
    try {
      // 检查代码是否已存在
      const exists = await this.isCodeExists(data.code);
      if (exists) {
        throw new ResponseError(ErrorCodes.SCENARIO.CODE_EXISTS, undefined, { scenarioCode: data.code });
      }

      return await this.create({
        ...data,
        isActive: data.isActive ?? true,
      });
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`创建场景失败: data=${JSON.stringify(data)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.CREATE_FAILED, error, { data });
    }
  }

  /**
   * 更新场景
   * @param id 场景ID
   * @param data 更新数据
   * @returns 更新后的场景
   */
  async updateScenario(id: string, data: any): Promise<any> {
    try {
      // 如果更新代码，检查是否与其他场景冲突
      if (data.code) {
        const exists = await this.isCodeExists(data.code, id);
        if (exists) {
          throw new ResponseError(ErrorCodes.SCENARIO.CODE_EXISTS, undefined, { scenarioCode: data.code });
        }
      }

      return await this.update({ id }, data);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`更新场景失败: id=${id}, data=${JSON.stringify(data)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.UPDATE_FAILED, error, { scenarioId: id, data });
    }
  }

  /**
   * 删除场景
   * @param id 场景ID
   * @returns 删除的场景
   */
  async deleteScenario(id: string): Promise<any> {
    try {
      return await this.delete({ id });
    } catch (error) {
      this.logger.error(`删除场景失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.DELETE_FAILED, error, { scenarioId: id });
    }
  }

  /**
   * 软删除场景（设置为非活跃）
   * @param id 场景ID
   * @returns 更新后的场景
   */
  async softDeleteScenario(id: string): Promise<any> {
    try {
      return await this.update({ id }, { isActive: false });
    } catch (error) {
      this.logger.error(`软删除场景失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.DELETE_FAILED, error, { scenarioId: id });
    }
  }

  /**
   * 批量更新场景状态
   * @param ids 场景ID数组
   * @param isActive 是否活跃
   * @returns 更新结果
   */
  async batchUpdateStatus(ids: string[], isActive: boolean): Promise<any> {
    try {
      return await this.updateMany(
        { id: { in: ids } },
        { isActive }
      );
    } catch (error) {
      this.logger.error(`批量更新场景状态失败: ids=${JSON.stringify(ids)}, isActive=${isActive}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.UPDATE_FAILED, error, { ids, isActive });
    }
  }

  /**
   * 获取场景相关的练习
   * @param scenarioId 场景ID
   * @returns 相关练习列表
   */
  async getRelatedExercises(scenarioId: string) {
    try {
      const scenario = await this.findUnique(
        { id: scenarioId },
        {
          exerciseScenarios: {
            include: {
              exercise: true
            }
          }
        }
      );

      return scenario?.exerciseScenarios?.map((es: any) => es.exercise) || [];
    } catch (error) {
      this.logger.error(`获取场景相关练习失败: scenarioId=${scenarioId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { scenarioId });
    }
  }
}
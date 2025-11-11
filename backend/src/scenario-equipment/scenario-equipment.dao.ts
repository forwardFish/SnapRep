import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';

/**
 * ScenarioEquipment DAO 类
 * 场景-器材关联表的数据库操作 (多对多关系)
 */
@Injectable()
export class ScenarioEquipmentDao extends PrismaBaseDao<any> {
  // private readonly logger = new Logger(ScenarioEquipmentDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    logger.info('ScenarioEquipmentDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.scenarioEquipment;
  }

  /**
   * 创建场景-器材关联关系
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @param isCommon 是否是常见器材
   * @returns 创建的关联关系
   */
  async createAssociation(scenarioId: string, equipmentId: string, isCommon: boolean = true): Promise<any> {
    try {
      return await this.create({
        scenarioId,
        equipmentId,
        isCommon,
      });
    } catch (error) {
      logger.error(`创建场景-器材关联失败: scenarioId=${scenarioId}, equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.CREATE_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 删除场景-器材关联关系
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @returns 删除的关联关系
   */
  async deleteAssociation(scenarioId: string, equipmentId: string): Promise<any> {
    try {
      return await this.delete({
        scenarioId_equipmentId: {
          scenarioId,
          equipmentId,
        },
      });
    } catch (error) {
      logger.error(`删除场景-器材关联失败: scenarioId=${scenarioId}, equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.DELETE_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 查找场景的所有器材
   * @param scenarioId 场景ID
   * @param onlyCommon 是否只返回常见器材
   * @returns 器材列表
   */
  async findEquipmentByScenario(scenarioId: string, onlyCommon: boolean = false): Promise<any[]> {
    try {
      const where: any = { scenarioId };
      if (onlyCommon) {
        where.isCommon = true;
      }

      const associations = await this.findMany(
        where,
        {
          equipment: true,
        }
      );

      return associations.map((assoc: any) => ({
        ...assoc.equipment,
        isCommon: assoc.isCommon,
      }));
    } catch (error) {
      logger.error(`获取场景器材失败: scenarioId=${scenarioId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { scenarioId });
    }
  }

  /**
   * 查找器材所在的场景
   * @param equipmentId 器材ID
   * @returns 场景列表
   */
  async findScenariosByEquipment(equipmentId: string): Promise<any[]> {
    try {
      const associations = await this.findMany(
        { equipmentId },
        {
          scenario: true,
        }
      );

      return associations.map((assoc: any) => ({
        ...assoc.scenario,
        isCommon: assoc.isCommon,
      }));
    } catch (error) {
      logger.error(`获取器材场景失败: equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { equipmentId });
    }
  }

  /**
   * 检查场景-器材关联是否存在
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @returns 是否存在
   */
  async associationExists(scenarioId: string, equipmentId: string): Promise<boolean> {
    try {
      return await this.exists({
        scenarioId,
        equipmentId,
      });
    } catch (error) {
      logger.error(`检查场景-器材关联失败: scenarioId=${scenarioId}, equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 批量创建场景-器材关联
   * @param scenarioId 场景ID
   * @param equipmentIds 器材ID列表
   * @param isCommon 是否是常见器材
   * @returns 创建结果
   */
  async createBatchAssociations(scenarioId: string, equipmentIds: string[], isCommon: boolean = true): Promise<any> {
    try {
      const data = equipmentIds.map(equipmentId => ({
        scenarioId,
        equipmentId,
        isCommon,
      }));

      return await this.createMany(data);
    } catch (error) {
      logger.error(`批量创建场景-器材关联失败: scenarioId=${scenarioId}, equipmentIds=${JSON.stringify(equipmentIds)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.CREATE_FAILED, error, { scenarioId, equipmentIds });
    }
  }

  /**
   * 更新关联关系的常见性
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @param isCommon 是否常见
   * @returns 更新结果
   */
  async updateAssociationCommonality(scenarioId: string, equipmentId: string, isCommon: boolean): Promise<any> {
    try {
      return await this.update(
        {
          scenarioId_equipmentId: {
            scenarioId,
            equipmentId,
          },
        },
        { isCommon }
      );
    } catch (error) {
      logger.error(`更新场景-器材关联常见性失败: scenarioId=${scenarioId}, equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.UPDATE_FAILED, error, { scenarioId, equipmentId, isCommon });
    }
  }
}
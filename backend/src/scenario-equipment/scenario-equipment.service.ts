import { Injectable, Logger } from '@nestjs/common';
import { ScenarioEquipmentDao } from './scenario-equipment.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import {
  CreateScenarioEquipmentDto,
  UpdateScenarioEquipmentDto,
  BatchCreateScenarioEquipmentDto,
  ScenarioEquipmentResponseDto,
  EquipmentWithAssociationDto,
  ScenarioWithAssociationDto,
} from './dto';

/**
 * ScenarioEquipment Service 类
 * 提供场景-器材关联关系的业务逻辑处理
 */
@Injectable()
export class ScenarioEquipmentService {
  private readonly logger = new Logger(ScenarioEquipmentService.name);

  constructor(private readonly scenarioEquipmentDao: ScenarioEquipmentDao) {
    this.logger.log('ScenarioEquipmentService initialized');
  }

  /**
   * 创建场景-器材关联
   * @param createDto 创建参数
   * @returns 创建的关联关系
   */
  async createAssociation(createDto: CreateScenarioEquipmentDto): Promise<ScenarioEquipmentResponseDto> {
    try {
      // 检查关联是否已存在
      const exists = await this.scenarioEquipmentDao.associationExists(
        createDto.scenarioId,
        createDto.equipmentId
      );

      if (exists) {
        throw new ResponseError(
          ErrorCodes.SCENARIO_EQUIPMENT.ALREADY_EXISTS,
          undefined,
          { scenarioId: createDto.scenarioId, equipmentId: createDto.equipmentId }
        );
      }

      const association = await this.scenarioEquipmentDao.createAssociation(
        createDto.scenarioId,
        createDto.equipmentId,
        createDto.isCommon
      );

      this.logger.log(`场景-器材关联创建成功: ${createDto.scenarioId} - ${createDto.equipmentId}`);
      return this.mapToResponseDto(association);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`创建场景-器材关联失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.CREATE_FAILED, error, {
        scenarioId: createDto.scenarioId,
        equipmentId: createDto.equipmentId,
        isCommon: createDto.isCommon?.toString(),
      });
    }
  }

  /**
   * 批量创建场景-器材关联
   * @param batchCreateDto 批量创建参数
   * @returns 创建结果
   */
  async createBatchAssociations(batchCreateDto: BatchCreateScenarioEquipmentDto): Promise<any> {
    try {
      const result = await this.scenarioEquipmentDao.createBatchAssociations(
        batchCreateDto.scenarioId,
        batchCreateDto.equipmentIds,
        batchCreateDto.isCommon
      );

      this.logger.log(`批量创建场景-器材关联成功: ${batchCreateDto.scenarioId}, 数量: ${batchCreateDto.equipmentIds.length}`);
      return result;
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`批量创建场景-器材关联失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.CREATE_FAILED, error, {
        scenarioId: batchCreateDto.scenarioId,
        equipmentIds: batchCreateDto.equipmentIds.join(','),
        isCommon: batchCreateDto.isCommon?.toString(),
      });
    }
  }

  /**
   * 更新关联关系的常见性
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @param updateDto 更新参数
   * @returns 更新后的关联关系
   */
  async updateAssociation(
    scenarioId: string,
    equipmentId: string,
    updateDto: UpdateScenarioEquipmentDto
  ): Promise<ScenarioEquipmentResponseDto> {
    try {
      // 检查关联是否存在
      const exists = await this.scenarioEquipmentDao.associationExists(scenarioId, equipmentId);
      if (!exists) {
        throw new ResponseError(
          ErrorCodes.SCENARIO_EQUIPMENT.NOT_FOUND,
          undefined,
          { scenarioId, equipmentId }
        );
      }

      const association = await this.scenarioEquipmentDao.updateAssociationCommonality(
        scenarioId,
        equipmentId,
        updateDto.isCommon
      );

      this.logger.log(`场景-器材关联更新成功: ${scenarioId} - ${equipmentId}`);
      return this.mapToResponseDto(association);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`更新场景-器材关联失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.UPDATE_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 删除场景-器材关联
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @returns 删除的关联关系
   */
  async deleteAssociation(scenarioId: string, equipmentId: string): Promise<ScenarioEquipmentResponseDto> {
    try {
      // 检查关联是否存在
      const exists = await this.scenarioEquipmentDao.associationExists(scenarioId, equipmentId);
      if (!exists) {
        throw new ResponseError(
          ErrorCodes.SCENARIO_EQUIPMENT.NOT_FOUND,
          undefined,
          { scenarioId, equipmentId }
        );
      }

      const association = await this.scenarioEquipmentDao.deleteAssociation(scenarioId, equipmentId);

      this.logger.log(`场景-器材关联删除成功: ${scenarioId} - ${equipmentId}`);
      return this.mapToResponseDto(association);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`删除场景-器材关联失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.DELETE_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 获取场景的所有器材
   * @param scenarioId 场景ID
   * @param onlyCommon 是否只返回常见器材
   * @returns 器材列表
   */
  async getEquipmentByScenario(scenarioId: string, onlyCommon: boolean = false): Promise<EquipmentWithAssociationDto[]> {
    try {
      const equipmentList = await this.scenarioEquipmentDao.findEquipmentByScenario(scenarioId, onlyCommon);
      return equipmentList.map(equipment => this.mapToEquipmentWithAssociation(equipment));
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取场景器材失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { scenarioId });
    }
  }

  /**
   * 获取器材所在的场景
   * @param equipmentId 器材ID
   * @returns 场景列表
   */
  async getScenariosByEquipment(equipmentId: string): Promise<ScenarioWithAssociationDto[]> {
    try {
      const scenarioList = await this.scenarioEquipmentDao.findScenariosByEquipment(equipmentId);
      return scenarioList.map(scenario => this.mapToScenarioWithAssociation(scenario));
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取器材场景失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { equipmentId });
    }
  }

  /**
   * 检查场景-器材关联是否存在
   * @param scenarioId 场景ID
   * @param equipmentId 器材ID
   * @returns 是否存在
   */
  async checkAssociationExists(scenarioId: string, equipmentId: string): Promise<boolean> {
    try {
      return await this.scenarioEquipmentDao.associationExists(scenarioId, equipmentId);
    } catch (error) {
      this.logger.error(`检查场景-器材关联失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED, error, { scenarioId, equipmentId });
    }
  }

  /**
   * 映射到响应 DTO
   * @param association 关联关系数据
   * @returns 响应 DTO
   */
  private mapToResponseDto(association: any): ScenarioEquipmentResponseDto {
    return {
      scenarioId: association.scenarioId,
      equipmentId: association.equipmentId,
      isCommon: association.isCommon,
      createdAt: association.createdAt,
      scenario: association.scenario,
      equipment: association.equipment,
    };
  }

  /**
   * 映射到器材关联 DTO
   * @param equipment 器材数据
   * @returns 器材关联 DTO
   */
  private mapToEquipmentWithAssociation(equipment: any): EquipmentWithAssociationDto {
    return {
      id: equipment.id,
      code: equipment.code,
      name: equipment.name,
      description: equipment.description,
      imageUrl: equipment.imageUrl,
      isCommon: equipment.isCommon,
      isActive: equipment.isActive,
      createdAt: equipment.createdAt,
      updatedAt: equipment.updatedAt,
    };
  }

  /**
   * 映射到场景关联 DTO
   * @param scenario 场景数据
   * @returns 场景关联 DTO
   */
  private mapToScenarioWithAssociation(scenario: any): ScenarioWithAssociationDto {
    return {
      id: scenario.id,
      code: scenario.code,
      name: scenario.name,
      description: scenario.description,
      isCommon: scenario.isCommon,
      isActive: scenario.isActive,
      createdAt: scenario.createdAt,
      updatedAt: scenario.updatedAt,
    };
  }
}
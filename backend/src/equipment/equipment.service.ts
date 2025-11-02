import { Injectable, Logger } from '@nestjs/common';
import { EquipmentDao } from './equipment.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import {
  GetEquipmentQueryDto,
  GetEquipmentResponseDto,
  GetEquipmentStatsResponseDto,
  GetEquipmentByCategoryResponseDto,
  CreateEquipmentDto,
  UpdateEquipmentDto,
  BatchUpdateEquipmentStatusDto,
  EquipmentDto,
} from './dto';

/**
 * Equipment Service 类
 * 提供器材相关的业务逻辑处理
 */
@Injectable()
export class EquipmentService {
  private readonly logger = new Logger(EquipmentService.name);

  constructor(private readonly equipmentDao: EquipmentDao) {
    this.logger.log('EquipmentService initialized');
  }

  /**
   * 获取器材列表 (分页)
   * @param queryDto 查询参数
   * @returns 分页器材列表
   */
  async findAll(queryDto: GetEquipmentQueryDto): Promise<GetEquipmentResponseDto> {
    try {
      const result = await this.equipmentDao.findEquipmentWithPagination(
        queryDto.page,
        queryDto.pageSize,
        queryDto.category,
        queryDto.includeInactive
      );

      return {
        data: result.data.map(equipment => this.mapToEquipmentDto(equipment)),
        pagination: result.pagination,
      };
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取器材列表失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.LIST_FAILED, error, { queryDto });
    }
  }

  /**
   * 根据ID获取器材详情
   * @param id 器材ID
   * @returns 器材详情
   */
  async findOne(id: string): Promise<EquipmentDto> {
    try {
      const equipment = await this.equipmentDao.findById(id);

      if (!equipment) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取器材详情失败: id=${id}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 根据代码获取器材详情
   * @param code 器材代码
   * @returns 器材详情
   */
  async findByCode(code: string): Promise<EquipmentDto> {
    try {
      const equipment = await this.equipmentDao.findByCode(code);

      if (!equipment) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentCode: code,
        });
      }

      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`根据代码获取器材详情失败: code=${code}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentCode: code });
    }
  }

  /**
   * 获取活跃器材列表
   * @param category 可选的分类筛选
   * @returns 活跃器材列表
   */
  async findActiveEquipment(category?: string): Promise<EquipmentDto[]> {
    try {
      const equipment = await this.equipmentDao.findActiveEquipment(category);
      return equipment.map(item => this.mapToEquipmentDto(item));
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取活跃器材列表失败: category=${category}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.LIST_FAILED, error, { category });
    }
  }

  /**
   * 按分类获取器材
   * @returns 按分类分组的器材
   */
  async findEquipmentByCategory(): Promise<GetEquipmentByCategoryResponseDto> {
    try {
      const equipmentByCategory = await this.equipmentDao.getEquipmentByCategory();

      const data: Record<string, EquipmentDto[]> = {};
      Object.entries(equipmentByCategory).forEach(([category, equipment]) => {
        data[category] = equipment.map(item => this.mapToEquipmentDto(item));
      });

      return { data };
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`按分类获取器材失败: error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error);
    }
  }

  /**
   * 获取器材统计信息
   * @returns 器材统计
   */
  async getEquipmentStats(): Promise<GetEquipmentStatsResponseDto> {
    try {
      const stats = await this.equipmentDao.getEquipmentStats();
      return stats;
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`获取器材统计失败: error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error);
    }
  }

  /**
   * 创建器材
   * @param createDto 创建器材数据
   * @returns 创建的器材
   */
  async create(createDto: CreateEquipmentDto): Promise<EquipmentDto> {
    try {
      // 验证必需字段
      if (!createDto.code || !createDto.name) {
        throw new ResponseError(ErrorCodes.COMMON.VALIDATION_ERROR, undefined, {
          missingFields: ['code', 'name'],
        });
      }

      const equipment = await this.equipmentDao.createEquipment({
        ...createDto,
        isActive: createDto.isActive ?? true,
      });

      this.logger.log(`器材创建成功: code=${equipment.code}, id=${equipment.id}`);
      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`创建器材失败: data=${JSON.stringify(createDto)}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.CREATE_FAILED, error, { createDto });
    }
  }

  /**
   * 更新器材
   * @param id 器材ID
   * @param updateDto 更新数据
   * @returns 更新后的器材
   */
  async update(id: string, updateDto: UpdateEquipmentDto): Promise<EquipmentDto> {
    try {
      // 检查器材是否存在
      const existingEquipment = await this.equipmentDao.findById(id, true);
      if (!existingEquipment) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      const equipment = await this.equipmentDao.updateEquipment(id, updateDto);

      this.logger.log(`器材更新成功: id=${id}, code=${equipment.code}`);
      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`更新器材失败: id=${id}, data=${JSON.stringify(updateDto)}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.UPDATE_FAILED, error, { equipmentId: id, updateDto });
    }
  }

  /**
   * 删除器材 (硬删除)
   * @param id 器材ID
   * @returns 删除的器材
   */
  async remove(id: string): Promise<EquipmentDto> {
    try {
      // 检查器材是否存在
      const existingEquipment = await this.equipmentDao.findById(id, true);
      if (!existingEquipment) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      const equipment = await this.equipmentDao.deleteEquipment(id);

      this.logger.log(`器材删除成功: id=${id}, code=${equipment.code}`);
      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`删除器材失败: id=${id}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.DELETE_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 软删除器材 (设置为非活跃)
   * @param id 器材ID
   * @returns 更新后的器材
   */
  async softRemove(id: string): Promise<EquipmentDto> {
    try {
      // 检查器材是否存在
      const existingEquipment = await this.equipmentDao.findById(id, true);
      if (!existingEquipment) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      const equipment = await this.equipmentDao.softDeleteEquipment(id);

      this.logger.log(`器材软删除成功: id=${id}, code=${equipment.code}`);
      return this.mapToEquipmentDto(equipment);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`软删除器材失败: id=${id}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.DELETE_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 批量更新器材状态
   * @param batchDto 批量更新数据
   * @returns 更新结果
   */
  async batchUpdateStatus(batchDto: BatchUpdateEquipmentStatusDto): Promise<{ count: number; message: string }> {
    try {
      const { ids, isActive } = batchDto;

      // 验证所有器材是否存在
      const existingEquipment = await Promise.all(
        ids.map(id => this.equipmentDao.findById(id, true))
      );

      const notFoundIds = ids.filter((id, index) => !existingEquipment[index]);
      if (notFoundIds.length > 0) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          notFoundIds,
        });
      }

      const result = await this.equipmentDao.batchUpdateStatus(ids, isActive);

      const message = `成功${isActive ? '激活' : '禁用'}了 ${result.count} 个器材`;
      this.logger.log(`批量更新器材状态成功: ${message}`);

      return {
        count: result.count,
        message,
      };
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`批量更新器材状态失败: data=${JSON.stringify(batchDto)}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.UPDATE_FAILED, error, { batchDto });
    }
  }

  /**
   * 验证器材代码是否唯一
   * @param code 器材代码
   * @param excludeId 排除的器材ID (用于更新时检查)
   * @returns 是否唯一
   */
  async isCodeUnique(code: string, excludeId?: string): Promise<boolean> {
    try {
      const existing = await this.equipmentDao.findByCode(code, true);
      if (!existing) {
        return true;
      }
      return excludeId ? existing.id === excludeId : false;
    } catch (error) {
      this.logger.error(`验证器材代码唯一性失败: code=${code}, error=${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentCode: code });
    }
  }

  /**
   * 将数据库实体映射为DTO
   * @param equipment 器材实体
   * @returns 器材DTO
   */
  private mapToEquipmentDto(equipment: any): EquipmentDto {
    return {
      id: equipment.id,
      code: equipment.code,
      name: equipment.name,
      description: equipment.description,
      category: equipment.category,
      imageUrl: equipment.imageUrl,
      displayOrder: equipment.displayOrder,
      isActive: equipment.isActive,
      createdAt: equipment.createdAt?.toISOString(),
      updatedAt: equipment.updatedAt?.toISOString(),
    };
  }
}
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

/**
 * Equipment DAO 类
 * 使用 Prisma ORM 进行数据库操作
 */
@Injectable()
export class EquipmentDao extends PrismaBaseDao<any> {
  private readonly logger = new Logger(EquipmentDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    this.logger.log('EquipmentDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.equipment;
  }

  /**
   * 根据ID查找器材
   * @param id 器材ID
   * @param includeInactive 是否包含非活跃器材
   * @returns 器材实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const where: any = { id };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(where);
    } catch (error) {
      this.logger.error(`根据ID查找器材失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 根据代码查找器材
   * @param code 器材代码
   * @param includeInactive 是否包含非活跃器材
   * @returns 器材实体或null
   */
  async findByCode(code: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const where: any = { code };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(where);
    } catch (error) {
      this.logger.error(`根据代码查找器材失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentCode: code });
    }
  }

  /**
   * 获取活跃器材列表
   * @param category 器材分类筛选
   * @returns 活跃器材列表
   */
  async findActiveEquipment(category?: string): Promise<any[]> {
    try {
      const where: any = { isActive: true };
      if (category) {
        where.category = category;
      }

      return await this.findMany(
        where,
        undefined,
        undefined,
        { displayOrder: 'asc' }
      );
    } catch (error) {
      this.logger.error(`获取活跃器材列表失败: category=${category}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.LIST_FAILED, error, { category });
    }
  }

  /**
   * 分页获取器材列表
   * @param page 页码
   * @param pageSize 每页大小
   * @param category 器材分类筛选
   * @param includeInactive 是否包含非活跃器材
   * @returns 分页器材列表
   */
  async findEquipmentWithPagination(
    page: number,
    pageSize: number,
    category?: string,
    includeInactive: boolean = false
  ) {
    try {
      const where: any = {};

      if (!includeInactive) {
        where.isActive = true;
      }

      if (category) {
        where.category = category;
      }

      return await this.findByPage(
        page,
        pageSize,
        where,
        undefined,
        undefined,
        { displayOrder: 'asc' }
      );
    } catch (error) {
      this.logger.error(
        `分页获取器材列表失败: page=${page}, pageSize=${pageSize}, category=${category}, error=${error.message}`
      );
      throw new ResponseError(ErrorCodes.EQUIPMENT.LIST_FAILED, error, { page, pageSize, category });
    }
  }

  /**
   * 根据分类获取器材分组
   * @returns 按分类分组的器材
   */
  async getEquipmentByCategory(): Promise<Record<string, any[]>> {
    try {
      const equipment = await this.findMany(
        { isActive: true },
        undefined,
        undefined,
        { displayOrder: 'asc' }
      );

      return equipment.reduce((groups: Record<string, any[]>, item: any) => {
        const category = item.category || 'OTHER';
        if (!groups[category]) {
          groups[category] = [];
        }
        groups[category].push(item);
        return groups;
      }, {});
    } catch (error) {
      this.logger.error(`按分类获取器材失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error);
    }
  }

  /**
   * 获取器材统计信息
   * @returns 器材统计
   */
  async getEquipmentStats(): Promise<any> {
    try {
      const [total, active, byCategory] = await Promise.all([
        this.count(),
        this.count({ isActive: true }),
        this.getEquipmentByCategory()
      ]);

      const categoryStats = Object.entries(byCategory).map(([category, items]) => ({
        category,
        count: items.length,
        items: items.map((item: any) => ({ id: item.id, code: item.code, name: item.name }))
      }));

      return {
        total,
        active,
        inactive: total - active,
        categories: categoryStats
      };
    } catch (error) {
      this.logger.error(`获取器材统计失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error);
    }
  }

  /**
   * 检查器材代码是否存在
   * @param code 器材代码
   * @param excludeId 排除的器材ID
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
      this.logger.error(`检查器材代码是否存在失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentCode: code });
    }
  }

  /**
   * 创建器材
   * @param data 器材数据
   * @returns 创建的器材
   */
  async createEquipment(data: any): Promise<any> {
    try {
      // 检查代码是否已存在
      const exists = await this.isCodeExists(data.code);
      if (exists) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.CODE_EXISTS, undefined, { equipmentCode: data.code });
      }

      return await this.create({
        ...data,
        isActive: data.isActive ?? true,
      });
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`创建器材失败: data=${JSON.stringify(data)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.CREATE_FAILED, error, { data });
    }
  }

  /**
   * 更新器材
   * @param id 器材ID
   * @param data 更新数据
   * @returns 更新后的器材
   */
  async updateEquipment(id: string, data: any): Promise<any> {
    try {
      // 如果更新代码，检查是否与其他器材冲突
      if (data.code) {
        const exists = await this.isCodeExists(data.code, id);
        if (exists) {
          throw new ResponseError(ErrorCodes.EQUIPMENT.CODE_EXISTS, undefined, { equipmentCode: data.code });
        }
      }

      return await this.update({ id }, data);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`更新器材失败: id=${id}, data=${JSON.stringify(data)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.UPDATE_FAILED, error, { equipmentId: id, data });
    }
  }

  /**
   * 删除器材
   * @param id 器材ID
   * @returns 删除的器材
   */
  async deleteEquipment(id: string): Promise<any> {
    try {
      return await this.delete({ id });
    } catch (error) {
      this.logger.error(`删除器材失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.DELETE_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 软删除器材（设置为非活跃）
   * @param id 器材ID
   * @returns 更新后的器材
   */
  async softDeleteEquipment(id: string): Promise<any> {
    try {
      return await this.update({ id }, { isActive: false });
    } catch (error) {
      this.logger.error(`软删除器材失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.DELETE_FAILED, error, { equipmentId: id });
    }
  }

  /**
   * 批量更新器材状态
   * @param ids 器材ID列表
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
      this.logger.error(
        `批量更新器材状态失败: ids=${JSON.stringify(ids)}, isActive=${isActive}, error=${error.message}`
      );
      throw new ResponseError(ErrorCodes.EQUIPMENT.UPDATE_FAILED, error, { equipmentIds: ids, isActive });
    }
  }

  /**
   * 获取器材相关的练习
   * @param equipmentId 器材ID
   * @returns 相关练习列表
   */
  async getRelatedExercises(equipmentId: string) {
    try {
      const equipment = await this.findUnique(
        { id: equipmentId },
        {
          exerciseEquipment: {
            include: {
              exercise: true
            }
          }
        }
      );

      return equipment?.exerciseEquipment?.map((ee: any) => ee.exercise) || [];
    } catch (error) {
      this.logger.error(`获取器材相关练习失败: equipmentId=${equipmentId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EQUIPMENT.FETCH_FAILED, error, { equipmentId });
    }
  }
}
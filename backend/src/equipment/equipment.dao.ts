import { Injectable, Logger } from '@nestjs/common';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

/**
 * Equipment DAO 类
 * TEMPORARY IMPLEMENTATION: Using mock data until Prisma client is working
 */
@Injectable()
export class EquipmentDao {
  private readonly logger = new Logger(EquipmentDao.name);

  // Mock data until Prisma is working
  private mockEquipment = [
    {
      id: 'eq-001',
      code: 'chair',
      name: 'Chair',
      description: 'Standard office or dining chair',
      category: 'FURNITURE',
      imageUrl: '/equipment/chair.jpg',
      displayOrder: 1,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'eq-002',
      code: 'wall',
      name: 'Wall',
      description: 'Any flat wall surface',
      category: 'WALL',
      imageUrl: '/equipment/wall.jpg',
      displayOrder: 2,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'eq-003',
      code: 'bottle',
      name: 'Water Bottle',
      description: 'Water bottle or similar container',
      category: 'BOTTLE',
      imageUrl: '/equipment/bottle.jpg',
      displayOrder: 3,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'eq-004',
      code: 'none',
      name: 'No Equipment',
      description: 'Bodyweight exercises requiring no equipment',
      category: 'NONE',
      imageUrl: '/equipment/none.jpg',
      displayOrder: 0,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  constructor() {
    this.logger.log('EquipmentDao initialized (temporary mode without Prisma)');
  }

  /**
   * 根据ID查找器材
   * @param id 器材ID
   * @param includeInactive 是否包含非活跃器材
   * @returns 器材实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const equipment = this.mockEquipment.find(item => item.id === id);

      if (!equipment) {
        return null;
      }

      // 检查是否为活跃器材
      if (!includeInactive && !equipment.isActive) {
        return null;
      }

      return equipment;
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
      let equipment = this.mockEquipment.find(item => item.code === code);

      if (!equipment) {
        return null;
      }

      if (!includeInactive && !equipment.isActive) {
        return null;
      }

      return equipment;
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
      let equipment = this.mockEquipment.filter(item => item.isActive);

      if (category) {
        equipment = equipment.filter(item => item.category === category);
      }

      return equipment.sort((a, b) => a.displayOrder - b.displayOrder);
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
      let equipment = this.mockEquipment;

      if (!includeInactive) {
        equipment = equipment.filter(item => item.isActive);
      }

      if (category) {
        equipment = equipment.filter(item => item.category === category);
      }

      // Sort by display order
      equipment = equipment.sort((a, b) => a.displayOrder - b.displayOrder);

      const total = equipment.length;
      const skip = (page - 1) * pageSize;
      const data = equipment.slice(skip, skip + pageSize);

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
      const equipment = this.mockEquipment.filter(item => item.isActive);

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
      const total = this.mockEquipment.length;
      const active = this.mockEquipment.filter(item => item.isActive).length;
      const byCategory = await this.getEquipmentByCategory();

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
   * 创建器材
   * @param data 器材数据
   * @returns 创建的器材
   */
  async createEquipment(data: any): Promise<any> {
    try {
      // 检查代码是否已存在
      if (this.mockEquipment.some(item => item.code === data.code)) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.CODE_EXISTS, undefined, {
          equipmentCode: data.code,
        });
      }

      const newEquipment = {
        id: `eq-${Date.now()}`,
        ...data,
        isActive: data.isActive ?? true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      this.mockEquipment.push(newEquipment);
      return newEquipment;
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
      const index = this.mockEquipment.findIndex(item => item.id === id);
      if (index === -1) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, { equipmentId: id });
      }

      // 如果更新了代码，检查是否已存在
      if (data.code && typeof data.code === 'string') {
        const existing = this.mockEquipment.find(item => item.code === data.code && item.id !== id);
        if (existing) {
          throw new ResponseError(ErrorCodes.EQUIPMENT.CODE_EXISTS, undefined, {
            equipmentCode: data.code,
          });
        }
      }

      const updatedEquipment = {
        ...this.mockEquipment[index],
        ...data,
        updatedAt: new Date(),
      };

      this.mockEquipment[index] = updatedEquipment;
      return updatedEquipment;
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
      const index = this.mockEquipment.findIndex(item => item.id === id);
      if (index === -1) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, { equipmentId: id });
      }

      const deletedEquipment = this.mockEquipment[index];
      this.mockEquipment.splice(index, 1);
      return deletedEquipment;
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
      return await this.updateEquipment(id, { isActive: false });
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
      let count = 0;
      for (const id of ids) {
        const index = this.mockEquipment.findIndex(item => item.id === id);
        if (index !== -1) {
          this.mockEquipment[index] = {
            ...this.mockEquipment[index],
            isActive,
            updatedAt: new Date(),
          };
          count++;
        }
      }

      return { count };
    } catch (error) {
      this.logger.error(
        `批量更新器材状态失败: ids=${JSON.stringify(ids)}, isActive=${isActive}, error=${error.message}`
      );
      throw new ResponseError(ErrorCodes.EQUIPMENT.UPDATE_FAILED, error, { equipmentIds: ids, isActive });
    }
  }
}
import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';

/**
 * Prisma基础DAO抽象类
 * 提供通用的CRUD操作和分页功能
 */
@Injectable()
export abstract class PrismaBaseDao<T> {
  protected constructor(protected readonly prisma: PrismaService) {}

  /**
   * 获取Prisma模型的委托对象
   * 子类必须实现此方法，返回对应的Prisma模型操作对象
   */
  protected abstract getDelegate(): any;

  /**
   * 创建实体
   * @param data 创建数据
   * @param include 包含关联数据
   * @returns 返回创建的实体
   */
  async create(data: any, include?: any): Promise<T> {
    try {
      const createOptions: any = { data };
      if (include) {
        createOptions.include = include;
      }
      return await this.getDelegate().create(createOptions);
    } catch (error) {
      this.handleError('Create failed', error, { data });
    }
  }

  /**
   * 根据唯一条件查询单条记录
   * @param where 唯一查询条件
   * @param include 包含关联数据
   * @param select 选择字段
   * @returns 返回找到的实体，未找到返回null
   */
  async findUnique(
    where: any,
    include?: any,
    select?: any
  ): Promise<T | null> {
    try {
      const findOptions: any = { where };
      if (include) {
        findOptions.include = include;
      }
      if (select) {
        findOptions.select = select;
      }
      return await this.getDelegate().findUnique(findOptions);
    } catch (error) {
      this.handleError('Find unique failed', error, { where });
    }
  }

  /**
   * 根据条件查询单条记录
   * @param where 查询条件
   * @param include 包含关联数据
   * @param select 选择字段
   * @param orderBy 排序条件
   * @returns 返回找到的实体，未找到返回null
   */
  async findFirst(
    where?: any,
    include?: any,
    select?: any,
    orderBy?: any
  ): Promise<T | null> {
    try {
      const findOptions: any = {};
      if (where) {
        findOptions.where = where;
      }
      if (include) {
        findOptions.include = include;
      }
      if (select) {
        findOptions.select = select;
      }
      if (orderBy) {
        findOptions.orderBy = orderBy;
      }
      return await this.getDelegate().findFirst(findOptions);
    } catch (error) {
      this.handleError('Find first failed', error, { where });
    }
  }

  /**
   * 查询多条记录
   * @param where 查询条件
   * @param include 包含关联数据
   * @param select 选择字段
   * @param orderBy 排序条件
   * @param skip 跳过记录数
   * @param take 获取记录数
   * @returns 返回符合条件的实体数组
   */
  async findMany(
    where?: any,
    include?: any,
    select?: any,
    orderBy?: any,
    skip?: number,
    take?: number
  ): Promise<T[]> {
    try {
      const findOptions: any = {};
      if (where) {
        findOptions.where = where;
      }
      if (include) {
        findOptions.include = include;
      }
      if (select) {
        findOptions.select = select;
      }
      if (orderBy) {
        findOptions.orderBy = orderBy;
      }
      if (skip !== undefined) {
        findOptions.skip = skip;
      }
      if (take !== undefined) {
        findOptions.take = take;
      }
      return await this.getDelegate().findMany(findOptions);
    } catch (error) {
      this.handleError('Find many failed', error, { where, skip, take });
    }
  }

  /**
   * 分页查询
   * @param page 页码（从1开始）
   * @param pageSize 每页记录数
   * @param where 查询条件
   * @param include 包含关联数据
   * @param select 选择字段
   * @param orderBy 排序条件
   * @returns 返回分页结果，包含数据和分页信息
   */
  async findByPage(
    page: number,
    pageSize: number,
    where?: any,
    include?: any,
    select?: any,
    orderBy?: any
  ): Promise<{
    data: T[];
    pagination: {
      total: number;
      page: number;
      pageSize: number;
      totalPages: number;
      hasNextPage: boolean;
      hasPreviousPage: boolean;
    };
  }> {
    try {
      const skip = Math.max(0, (page - 1) * pageSize);
      const take = Math.max(1, Math.min(pageSize, 100)); // 限制最大页面大小

      // 并行查询数据和总数
      const [data, total] = await Promise.all([
        this.findMany(where, include, select, orderBy, skip, take),
        this.count(where),
      ]);

      const totalPages = Math.ceil(total / take);

      return {
        data,
        pagination: {
          total,
          page,
          pageSize: take,
          totalPages,
          hasNextPage: page < totalPages,
          hasPreviousPage: page > 1,
        },
      };
    } catch (error) {
      this.handleError('Find by page failed', error, { page, pageSize, where });
    }
  }

  /**
   * 更新记录
   * @param where 更新条件
   * @param data 更新数据
   * @param include 包含关联数据
   * @returns 返回更新后的实体
   */
  async update(
    where: any,
    data: any,
    include?: any
  ): Promise<T> {
    try {
      const updateOptions: any = { where, data };
      if (include) {
        updateOptions.include = include;
      }
      return await this.getDelegate().update(updateOptions);
    } catch (error) {
      this.handleError('Update failed', error, { where, data });
    }
  }

  /**
   * 批量更新记录
   * @param where 更新条件
   * @param data 更新数据
   * @returns 返回更新结果
   */
  async updateMany(
    where: any,
    data: any
  ): Promise<any> {
    try {
      return await this.getDelegate().updateMany({ where, data });
    } catch (error) {
      this.handleError('Update many failed', error, { where, data });
    }
  }

  /**
   * 删除记录
   * @param where 删除条件
   * @returns 返回删除的实体
   */
  async delete(where: any): Promise<T> {
    try {
      return await this.getDelegate().delete({ where });
    } catch (error) {
      this.handleError('Delete failed', error, { where });
    }
  }

  /**
   * 批量删除记录
   * @param where 删除条件
   * @returns 返回删除结果
   */
  async deleteMany(where: any): Promise<any> {
    try {
      return await this.getDelegate().deleteMany({ where });
    } catch (error) {
      this.handleError('Delete many failed', error, { where });
    }
  }

  /**
   * 统计记录数量
   * @param where 统计条件
   * @returns 返回符合条件的记录数量
   */
  async count(where?: any): Promise<number> {
    try {
      const countOptions: any = {};
      if (where) {
        countOptions.where = where;
      }
      return await this.getDelegate().count(countOptions);
    } catch (error) {
      this.handleError('Count failed', error, { where });
    }
  }

  /**
   * 检查记录是否存在
   * @param where 查询条件
   * @returns 返回是否存在
   */
  async exists(where: any): Promise<boolean> {
    try {
      const count = await this.count(where);
      return count > 0;
    } catch (error) {
      this.handleError('Exists check failed', error, { where });
    }
  }

  /**
   * Upsert操作（存在则更新，不存在则创建）
   * @param where 唯一查询条件
   * @param create 创建数据
   * @param update 更新数据
   * @param include 包含关联数据
   * @returns 返回操作后的实体
   */
  async upsert(
    where: any,
    create: any,
    update: any,
    include?: any
  ): Promise<T> {
    try {
      const upsertOptions: any = { where, create, update };
      if (include) {
        upsertOptions.include = include;
      }
      return await this.getDelegate().upsert(upsertOptions);
    } catch (error) {
      this.handleError('Upsert failed', error, { where, create, update });
    }
  }

  /**
   * 批量创建记录
   * @param data 创建数据数组
   * @param skipDuplicates 是否跳过重复记录
   * @returns 返回创建结果
   */
  async createMany(
    data: any[],
    skipDuplicates?: boolean
  ): Promise<any> {
    try {
      return await this.getDelegate().createMany({
        data,
        skipDuplicates,
      });
    } catch (error) {
      this.handleError('Create many failed', error, { data });
    }
  }

  /**
   * 开始事务
   * @param fn 事务函数
   * @returns 返回事务结果
   */
  async transaction<R>(
    fn: (prisma: PrismaService) => Promise<R>
  ): Promise<R> {
    try {
      return await this.prisma.$transaction(fn);
    } catch (error) {
      this.handleError('Transaction failed', error);
    }
  }

  /**
   * 处理错误
   * @param message 错误消息
   * @param error 原始错误
   * @param context 上下文信息
   */
  protected handleError(
    message: string,
    error: any,
    context?: Record<string, any>
  ): never {
    const errorMessage = `${message}: ${error.message}`;
    const errorContext = {
      originalError: error,
      context,
      timestamp: new Date().toISOString(),
    };

    // 根据错误类型进行不同的处理
    if (error.code === 'P2002') {
      // Prisma unique constraint violation
      const newError = new Error(`${errorMessage} (Unique constraint violation)`);
      (newError as any).originalCause = errorContext;
      throw newError;
    } else if (error.code === 'P2025') {
      // Prisma record not found
      const newError = new Error(`${errorMessage} (Record not found)`);
      (newError as any).originalCause = errorContext;
      throw newError;
    } else {
      // 其他错误
      const newError = new Error(errorMessage);
      (newError as any).originalCause = errorContext;
      throw newError;
    }
  }
}
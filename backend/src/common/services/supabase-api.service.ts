import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * 通用的 Supabase REST API 调用服务
 * 用于绕过 Prisma 数据库连接问题的临时解决方案
 */
@Injectable()
export class SupabaseApiService {
  private readonly logger = new Logger(SupabaseApiService.name);
  private readonly supabaseUrl: string;
  private readonly anonKey: string;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    this.anonKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (!this.supabaseUrl || !this.anonKey) {
      throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
    }
  }

  /**
   * 执行 GET 请求到 Supabase REST API
   * @param table 表名
   * @param filters 查询过滤器对象
   * @param options 额外选项
   */
  async get<T = any>(
    table: string,
    filters: Record<string, any> = {},
    options: {
      limit?: number;
      offset?: number;
      orderBy?: string;
      select?: string;
    } = {},
  ): Promise<T[]> {
    const searchParams = new URLSearchParams();

    // 添加过滤器
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        searchParams.append(key, `eq.${value}`);
      }
    });

    // 添加分页和排序参数
    if (options.limit) {
      searchParams.append('limit', options.limit.toString());
    }
    if (options.offset) {
      searchParams.append('offset', options.offset.toString());
    }
    if (options.orderBy) {
      searchParams.append('order', options.orderBy);
    }
    if (options.select) {
      searchParams.append('select', options.select);
    }

    const url = `${this.supabaseUrl}/rest/v1/${table}?${searchParams}`;

    this.logger.debug(`Making Supabase API request: ${url}`);

    try {
      const response = await fetch(url, {
        headers: {
          'apikey': this.anonKey,
          'Authorization': `Bearer ${this.anonKey}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      this.logger.debug(`Supabase API response: ${data.length} records`);
      return data;
    } catch (error) {
      this.logger.error(`Supabase API call failed:`, error);
      throw error;
    }
  }

  /**
   * 根据ID获取单条记录
   * @param table 表名
   * @param id 记录ID
   * @param select 选择字段
   */
  async getById<T = any>(table: string, id: string, select?: string): Promise<T | null> {
    const data = await this.get<T>(table, { id }, { select, limit: 1 });
    return data.length > 0 ? data[0] : null;
  }

  /**
   * 根据字段值获取单条记录
   * @param table 表名
   * @param field 字段名
   * @param value 字段值
   * @param select 选择字段
   */
  async getByField<T = any>(
    table: string,
    field: string,
    value: any,
    select?: string,
  ): Promise<T | null> {
    const filters = { [field]: value };
    const data = await this.get<T>(table, filters, { select, limit: 1 });
    return data.length > 0 ? data[0] : null;
  }

  /**
   * 执行 POST 请求到 Supabase REST API
   * @param table 表名
   * @param data 要插入的数据
   */
  async post<T = any>(table: string, data: Record<string, any>): Promise<T> {
    const url = `${this.supabaseUrl}/rest/v1/${table}`;

    this.logger.debug(`Making Supabase POST request: ${url}`);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'apikey': this.anonKey,
          'Authorization': `Bearer ${this.anonKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      this.logger.debug(`Supabase POST response: success`);
      return result[0]; // Supabase returns array even for single insert
    } catch (error) {
      this.logger.error(`Supabase POST call failed:`, error);
      throw error;
    }
  }

  /**
   * 执行 PATCH 请求到 Supabase REST API
   * @param table 表名
   * @param id 记录ID
   * @param data 要更新的数据
   */
  async patch<T = any>(table: string, id: string, data: Record<string, any>): Promise<T> {
    const url = `${this.supabaseUrl}/rest/v1/${table}?id=eq.${id}`;

    this.logger.debug(`Making Supabase PATCH request: ${url}`);

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'apikey': this.anonKey,
          'Authorization': `Bearer ${this.anonKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      this.logger.debug(`Supabase PATCH response: success`);
      return result[0];
    } catch (error) {
      this.logger.error(`Supabase PATCH call failed:`, error);
      throw error;
    }
  }

  /**
   * 执行 DELETE 请求到 Supabase REST API
   * @param table 表名
   * @param id 记录ID
   */
  async delete(table: string, id: string): Promise<void> {
    const url = `${this.supabaseUrl}/rest/v1/${table}?id=eq.${id}`;

    this.logger.debug(`Making Supabase DELETE request: ${url}`);

    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'apikey': this.anonKey,
          'Authorization': `Bearer ${this.anonKey}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      this.logger.debug(`Supabase DELETE response: success`);
    } catch (error) {
      this.logger.error(`Supabase DELETE call failed:`, error);
      throw error;
    }
  }

  /**
   * 执行聚合查询
   * @param table 表名
   * @param filters 查询过滤器
   */
  async count(table: string, filters: Record<string, any> = {}): Promise<number> {
    const searchParams = new URLSearchParams();
    searchParams.append('select', 'count');

    // 添加过滤器
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        searchParams.append(key, `eq.${value}`);
      }
    });

    const url = `${this.supabaseUrl}/rest/v1/${table}?${searchParams}`;

    this.logger.debug(`Making Supabase COUNT request: ${url}`);

    try {
      const response = await fetch(url, {
        headers: {
          'apikey': this.anonKey,
          'Authorization': `Bearer ${this.anonKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact',
        },
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const countHeader = response.headers.get('Content-Range');
      const count = countHeader ? parseInt(countHeader.split('/')[1]) : 0;

      this.logger.debug(`Supabase COUNT response: ${count}`);
      return count;
    } catch (error) {
      this.logger.error(`Supabase COUNT call failed:`, error);
      throw error;
    }
  }
}
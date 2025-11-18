import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { logger } from '../../common/logger/logger';

/**
 * 通用的 Supabase REST API 调用服务
 * 用于绕过 Prisma 数据库连接问题的临时解决方案
 */
@Injectable()
export class SupabaseApiService {
  // private readonly logger = new Logger(SupabaseApiService.name);
  private readonly supabaseUrl: string;
  private readonly anonKey: string;
  private readonly serviceKey: string;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    this.anonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
    this.serviceKey = this.configService.get<string>('SUPABASE_SERVICE_KEY');

    if (!this.supabaseUrl || !this.anonKey) {
      throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
    }

    if (!this.serviceKey) {
      logger.warn('SUPABASE_SERVICE_KEY not found, write operations may fail due to RLS policies');
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
    logger.debug(`🔍 Supabase GET called - Table: ${table}`);
    logger.debug(`🔍 Filters: ${JSON.stringify(filters)}`);
    logger.debug(`🔍 Options: ${JSON.stringify(options)}`);

    const searchParams = new URLSearchParams();

    // 添加过滤器
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        // 检查是否已经包含操作符（如 in.、eq.、gte. 等）
        if (typeof value === 'string' && value.includes('.')) {
          // 如果已包含操作符，直接使用
          searchParams.append(key, value);
        } else {
          // 否则默认使用等值查询
          searchParams.append(key, `eq.${value}`);
        }
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

    logger.debug(`📡 Making Supabase API request: ${url}`);

    try {
      // 优先使用 service key 来绕过 RLS 策略
      const authKey = this.serviceKey || this.anonKey;
      const keyType = this.serviceKey ? 'SERVICE_KEY' : 'ANON_KEY';

      logger.debug(`🔑 Using ${keyType} for authentication`);
      logger.debug(`🔑 Auth key length: ${authKey?.length || 0} characters`);

      const response = await fetch(url, {
        headers: {
          'apikey': authKey,
          'Authorization': `Bearer ${authKey}`,
          'Content-Type': 'application/json',
        },
      });

      logger.debug(`📊 HTTP Response status: ${response.status} ${response.statusText}`);

      if (!response.ok) {
        // 安全地读取错误响应
        let errorMessage = `Supabase API error: ${response.status} ${response.statusText}`;
        try {
          const errorBody = await response.text(); // 使用 text() 避免 JSON 解析错误
          if (errorBody) {
            errorMessage += ` - ${errorBody}`;
            logger.error(`❌ Error response body: ${errorBody}`);
          }
        } catch (readError) {
          logger.warn('Failed to read error response body:', readError.message);
        }
        throw new Error(errorMessage);
      }

      const data = await response.json();
      logger.debug(`✅ Supabase API response: ${data.length} records`);

      if (data.length > 0) {
        logger.debug(`📝 First record keys: ${Object.keys(data[0])}`);
      }

      return data;
    } catch (error) {
      logger.error(`💥 Supabase API call failed for table: ${table}`);
      logger.error(`🔥 Error type: ${error.constructor?.name}`);
      logger.error(`📝 Error message: ${error.message}`);
      logger.error(`📊 Error stack: ${error.stack}`);
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
    logger.debug(`🔍 getById called - Table: ${table}, ID: ${id}`);

    if (!id) {
      logger.error('❌ ID parameter is null or undefined');
      return null;
    }

    const data = await this.get<T>(table, { id }, { select, limit: 1 });

    if (data.length > 0) {
      logger.debug(`✅ Record found for ID: ${id}`);
      return data[0];
    } else {
      logger.warn(`⚠️ No record found for ID: ${id} in table: ${table}`);
      return null;
    }
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

    logger.debug(`Making Supabase POST request: ${url}`);

    try {
      const authKey = this.serviceKey || this.anonKey; // 优先使用service key进行写操作

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'apikey': authKey,
          'Authorization': `Bearer ${authKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        let errorDetails = '';
        try {
          const errorBody = await response.text();
          errorDetails = `: ${errorBody}`;
          logger.error(`Supabase POST API error details: ${errorBody}`);
        } catch (e) {
          // Ignore error body parsing errors
        }
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}${errorDetails}`);
      }

      const result = await response.json();
      logger.debug(`Supabase POST response: success`);
      return result[0]; // Supabase returns array even for single insert
    } catch (error) {
      logger.error(`Supabase POST call failed:`, error);
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

    logger.debug(`Making Supabase PATCH request: ${url}`);

    try {
      const authKey = this.serviceKey || this.anonKey; // 优先使用service key进行写操作

      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'apikey': authKey,
          'Authorization': `Bearer ${authKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      logger.debug(`Supabase PATCH response: success`);
      return result[0];
    } catch (error) {
      logger.error(`Supabase PATCH call failed:`, error);
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

    logger.debug(`Making Supabase DELETE request: ${url}`);

    try {
      const authKey = this.serviceKey || this.anonKey; // 优先使用service key进行写操作

      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'apikey': authKey,
          'Authorization': `Bearer ${authKey}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      logger.debug(`Supabase DELETE response: success`);
    } catch (error) {
      logger.error(`Supabase DELETE call failed:`, error);
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

    logger.debug(`Making Supabase COUNT request: ${url}`);

    try {
      // 优先使用 service key 来绕过 RLS 策略
      const authKey = this.serviceKey || this.anonKey;

      const response = await fetch(url, {
        headers: {
          'apikey': authKey,
          'Authorization': `Bearer ${authKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact',
        },
      });

      if (!response.ok) {
        throw new Error(`Supabase API error: ${response.status} ${response.statusText}`);
      }

      const countHeader = response.headers.get('Content-Range');
      const count = countHeader ? parseInt(countHeader.split('/')[1]) : 0;

      logger.debug(`Supabase COUNT response: ${count}`);
      return count;
    } catch (error) {
      logger.error(`Supabase COUNT call failed:`, error);
      throw error;
    }
  }
}
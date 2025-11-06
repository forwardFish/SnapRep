import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SupabaseHttpService {
  private readonly logger = new Logger(SupabaseHttpService.name);
  private readonly supabaseUrl: string;
  private readonly serviceKey: string;
  private readonly anonKey: string;

  constructor(private configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    this.serviceKey = this.configService.get<string>('SUPABASE_SERVICE_KEY');
    this.anonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
  }

  /**
   * 通用Supabase REST API请求
   */
  async request<T>(
    method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD',
    path: string,
    options: {
      body?: any;
      params?: Record<string, string>;
      useServiceKey?: boolean;
    } = {},
  ): Promise<{ data: T; error?: any }> {
    const { body, params, useServiceKey = false } = options;

    // 构建URL
    const url = new URL(`${this.supabaseUrl}/rest/v1${path}`);
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        url.searchParams.append(key, value);
      });
    }

    // 构建headers
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'apikey': useServiceKey ? this.serviceKey : this.anonKey,
      'Authorization': `Bearer ${useServiceKey ? this.serviceKey : this.anonKey}`,
    };

    try {
      const response = await fetch(url.toString(), {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
      });

      const responseText = await response.text();
      let responseData;

      try {
        responseData = responseText ? JSON.parse(responseText) : null;
      } catch {
        responseData = responseText;
      }

      if (!response.ok) {
        this.logger.error(`Supabase request failed: ${response.status} ${response.statusText}`, {
          url: url.toString(),
          method,
          response: responseData,
        });

        return {
          data: null as T,
          error: {
            status: response.status,
            message: response.statusText,
            details: responseData,
          },
        };
      }

      return { data: responseData as T };
    } catch (error) {
      this.logger.error('Supabase HTTP request error', {
        error: error.message,
        url: url.toString(),
        method,
      });

      return {
        data: null as T,
        error: {
          message: error.message,
          type: 'NETWORK_ERROR',
        },
      };
    }
  }

  /**
   * 查询数据
   */
  async select<T>(
    table: string,
    options: {
      select?: string;
      where?: Record<string, any>;
      order?: string;
      limit?: number;
      offset?: number;
    } = {},
  ): Promise<{ data: T[]; error?: any; count?: number }> {
    const { select = '*', where, order, limit, offset } = options;

    const params: Record<string, string> = {
      select,
    };

    // 添加where条件
    if (where) {
      Object.entries(where).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          if (typeof value === 'boolean') {
            params[key] = `eq.${value}`;
          } else {
            params[key] = `eq.${value}`;
          }
        }
      });
    }

    // 添加排序
    if (order) {
      params['order'] = order;
    }

    // 添加分页
    if (limit) {
      params['limit'] = limit.toString();
    }
    if (offset) {
      params['offset'] = offset.toString();
    }

    const result = await this.request<T[]>('GET', `/${table}`, {
      params,
      useServiceKey: true,
    });

    return result;
  }

  /**
   * 插入数据
   */
  async insert<T>(
    table: string,
    data: any,
    options: { returning?: boolean } = {},
  ): Promise<{ data: T; error?: any }> {
    const { returning = true } = options;

    const headers: Record<string, string> = {
      'Prefer': returning ? 'return=representation' : 'return=minimal',
    };

    const params: Record<string, string> = {};

    const result = await this.request<T>('POST', `/${table}`, {
      body: data,
      params,
      useServiceKey: true,
    });

    return result;
  }

  /**
   * 更新数据
   */
  async update<T>(
    table: string,
    data: any,
    where: Record<string, any>,
    options: { returning?: boolean } = {},
  ): Promise<{ data: T[]; error?: any }> {
    const { returning = true } = options;

    const params: Record<string, string> = {};

    // 添加where条件
    Object.entries(where).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        params[key] = `eq.${value}`;
      }
    });

    if (returning) {
      params['select'] = '*';
    }

    const result = await this.request<T[]>('PATCH', `/${table}`, {
      body: data,
      params,
      useServiceKey: true,
    });

    return result;
  }

  /**
   * 删除数据
   */
  async delete<T>(
    table: string,
    where: Record<string, any>,
    options: { returning?: boolean } = {},
  ): Promise<{ data: T[]; error?: any }> {
    const { returning = false } = options;

    const params: Record<string, string> = {};

    // 添加where条件
    Object.entries(where).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        params[key] = `eq.${value}`;
      }
    });

    if (returning) {
      params['select'] = '*';
    }

    const result = await this.request<T[]>('DELETE', `/${table}`, {
      params,
      useServiceKey: true,
    });

    return result;
  }

  /**
   * 计数
   */
  async count(
    table: string,
    where?: Record<string, any>,
  ): Promise<{ count: number; error?: any }> {
    const params: Record<string, string> = {
      select: '*',
      count: 'exact',
    };

    // 添加where条件
    if (where) {
      Object.entries(where).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params[key] = `eq.${value}`;
        }
      });
    }

    const result = await this.request('HEAD', `/${table}`, {
      params,
      useServiceKey: true,
    });

    // Supabase在HEAD请求的响应头中返回计数
    return { count: 0, error: result.error };
  }
}
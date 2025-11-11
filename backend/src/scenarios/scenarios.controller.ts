import {
  Controller,
  Get,
  Query,
  Param,
  HttpStatus,
  NotFoundException,
  BadRequestException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
} from '@nestjs/swagger';
import { ScenariosService } from './scenarios.service';
import { GetScenariosQueryDto } from './dto/get-scenarios-query.dto';
import {
  GetScenariosResponseDto,
  ScenarioResponseDto,
} from './dto/get-scenarios-response.dto';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { ConfigService } from '@nestjs/config';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';

@ApiTags('scenarios')
@Controller('rest/v1/scenarios')
export class ScenariosController {
  // private readonly logger = new Logger(ScenariosController.name);

  constructor(
    private readonly scenariosService: ScenariosService,
    private readonly configService: ConfigService,
    private readonly supabaseApi: SupabaseApiService, // 注入SupabaseApiService
  ) {}

  /**
   * 使用SupabaseApiService获取场景列表
   * 替换原来的直接fetch调用
   */
  private async getScenariosDirect(): Promise<any> {
    try {
      const scenarios = await this.supabaseApi.get('scenarios',
        { is_active: true },
        { orderBy: 'created_at.asc' }
      );

      return {
        data: scenarios.map((scenario: any) => ({
          id: scenario.id,
          code: scenario.code,
          name: scenario.name,
          noiseTolerance: scenario.noise_tolerance,
          spaceRequirement: scenario.space_requirement,
          iconUrl: scenario.icon_url,
          isActive: scenario.is_active,
          createdAt: scenario.created_at,
          updatedAt: scenario.updated_at,
        })),
        pagination: {
          total: scenarios.length,
          page: 1,
          pageSize: scenarios.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        },
      };
    } catch (error) {
      logger.error('SupabaseApiService call failed:', error);
      throw new InternalServerErrorException('Failed to fetch scenarios');
    }
  }

  /**
   * 获取场景列表
   * 用途: 首页场景区显示「办公室」「客厅/沙发」等场景选项
   */
  @Get()
  @ApiOperation({ summary: '获取场景列表' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '成功获取场景列表',
    type: GetScenariosResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findAll(
    @Query() queryDto: GetScenariosQueryDto,
  ): Promise<GetScenariosResponseDto> {
    try {
      logger.info('Using SupabaseApiService due to database connection issue');
      return await this.getScenariosDirect();
    } catch (error) {
      this.handleError(error, 'findAll', { queryDto });
    }
  }

  /**
   * 根据ID获取单个场景
   */
  @Get(':id')
  @ApiOperation({
    summary: '获取单个场景详情',
    description: '根据场景ID获取详细信息',
  })
  @ApiParam({
    name: 'id',
    description: '场景ID',
    example: 'scenario-001',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '成功获取场景详情',
    type: ScenarioResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '场景不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findOne(@Param('id') id: string): Promise<ScenarioResponseDto> {
    try {
      logger.info(`获取场景详情: id=${id}`);
      logger.info('Using SupabaseApiService due to database connection issue');

      const scenario = await this.supabaseApi.getById('scenarios', id);
      if (!scenario) {
        throw new NotFoundException(`Scenario with ID ${id} not found`);
      }

      return {
        id: scenario.id,
        code: scenario.code,
        name: scenario.name,
        noiseTolerance: scenario.noise_tolerance,
        spaceRequirement: scenario.space_requirement,
        iconUrl: scenario.icon_url,
        isActive: scenario.is_active,
        createdAt: scenario.created_at,
        updatedAt: scenario.updated_at,
      };
    } catch (error) {
      this.handleError(error, 'findOne', { scenarioId: id });
    }
  }

  /**
   * 根据代码获取场景
   */
  @Get('code/:code')
  @ApiOperation({
    summary: '根据代码获取场景',
    description: '根据场景代码获取详细信息',
  })
  @ApiParam({
    name: 'code',
    description: '场景代码',
    example: 'office',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '成功获取场景详情',
    type: ScenarioResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '场景不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findByCode(@Param('code') code: string): Promise<ScenarioResponseDto> {
    try {
      logger.info(`根据代码获取场景: code=${code}`);
      logger.info('Using SupabaseApiService due to database connection issue');

      const scenario = await this.supabaseApi.getByField('scenarios', 'code', code);
      if (!scenario) {
        throw new NotFoundException(`Scenario with code ${code} not found`);
      }

      return {
        id: scenario.id,
        code: scenario.code,
        name: scenario.name,
        noiseTolerance: scenario.noise_tolerance,
        spaceRequirement: scenario.space_requirement,
        iconUrl: scenario.icon_url,
        isActive: scenario.is_active,
        createdAt: scenario.created_at,
        updatedAt: scenario.updated_at,
      };
    } catch (error) {
      this.handleError(error, 'findByCode', { scenarioCode: code });
    }
  }

  /**
   * 获取活跃场景数量统计
   */
  @Get('stats/count')
  @ApiOperation({
    summary: '获取活跃场景数量',
    description: '返回当前活跃场景的总数量',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '成功获取统计数据',
    schema: {
      type: 'object',
      properties: {
        count: {
          type: 'number',
          description: '活跃场景数量',
          example: 8,
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async getActiveCount(): Promise<{ count: number }> {
    try {
      logger.info('Using SupabaseApiService to get active scenarios count');
      const scenarios = await this.supabaseApi.get('scenarios',
        { is_active: true },
        { orderBy: 'created_at.asc' }
      );
      const count = scenarios.length;
      logger.info(`Found ${count} active scenarios`);
      return { count };
    } catch (error) {
      this.handleError(error, 'getActiveCount');
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`${method} failed`, {
      error: error.message,
      context,
      stack: error.stack,
    });

    if (error instanceof ResponseError) {
      // 根据错误代码映射到HTTP状态码
      switch (error.code) {
        case ErrorCodes.SCENARIO.NOT_FOUND.code:
          throw error; // 直接抛出 ResponseError
        case ErrorCodes.SCENARIO.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw error; // 直接抛出 ResponseError
        case ErrorCodes.SCENARIO.FETCH_FAILED.code:
        case ErrorCodes.SCENARIO.LIST_FAILED.code:
        case ErrorCodes.SCENARIO.COUNT_FAILED.code:
        default:
          throw new InternalServerErrorException('服务器内部错误，请稍后重试');
      }
    }

    // 未知错误
    throw new InternalServerErrorException('服务器内部错误，请稍后重试');
  }
}
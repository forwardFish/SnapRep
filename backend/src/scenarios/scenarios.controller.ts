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
  ApiQuery,
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

@ApiTags('scenarios')
@Controller('rest/v1/scenarios')
export class ScenariosController {
  private readonly logger = new Logger(ScenariosController.name);

  constructor(private readonly scenariosService: ScenariosService) {}

  /**
   * 获取场景列表
   * 用途: 首页场景区显示「办公室」「客厅/沙发」等场景选项
   */
  @Get()
  @ApiOperation({
    summary: '获取场景列表',
    description: '首页场景区显示「办公室」「客厅/沙发」等场景选项',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: '页码，默认值 1',
    example: 1,
  })
  @ApiQuery({
    name: 'pageSize',
    required: false,
    type: Number,
    description: '每页数量，默认值 10',
    example: 20,
  })
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
      return await this.scenariosService.findAll(queryDto);
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
      return await this.scenariosService.findOne(id);
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
      return await this.scenariosService.findByCode(code);
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
      const count = await this.scenariosService.getActiveCount();
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
    this.logger.error(`${method} failed`, {
      error: error.message,
      context,
      stack: error.stack,
    });

    if (error instanceof ResponseError) {
      // 根据错误代码映射到HTTP状态码
      switch (error.code) {
        case ErrorCodes.SCENARIO.NOT_FOUND.code:
          throw new NotFoundException(error.getUserMessage());
        case ErrorCodes.SCENARIO.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw new BadRequestException(error.getUserMessage());
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
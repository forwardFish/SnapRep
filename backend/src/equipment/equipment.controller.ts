import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpStatus,
  Logger,
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
  ConflictException,
  ValidationPipe,
  UsePipes,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { EquipmentService } from './equipment.service';
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
 * Equipment Controller 类
 * 提供器材相关的REST API接口
 */
@ApiTags('Equipment')
@Controller('rest/v1/equipment')
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class EquipmentController {
  private readonly logger = new Logger(EquipmentController.name);

  constructor(private readonly equipmentService: EquipmentService) {}

  /**
   * 获取器材列表 (分页)
   */
  @Get()
  @ApiOperation({
    summary: '获取器材列表',
    description: '分页获取器材列表，支持按分类筛选和包含非活跃器材',
  })
  @ApiQuery({ type: GetEquipmentQueryDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: GetEquipmentResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findAll(@Query() queryDto: GetEquipmentQueryDto): Promise<GetEquipmentResponseDto> {
    try {
      this.logger.log(`获取器材列表: ${JSON.stringify(queryDto)}`);
      return await this.equipmentService.findAll(queryDto);
    } catch (error) {
      this.handleError(error, 'findAll', { queryDto });
    }
  }

  /**
   * 根据ID获取器材详情
   */
  @Get(':id')
  @ApiOperation({
    summary: '获取器材详情',
    description: '根据器材ID获取详细信息',
  })
  @ApiParam({
    name: 'id',
    description: '器材ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findOne(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      this.logger.log(`获取器材详情: id=${id}`);
      return await this.equipmentService.findOne(id);
    } catch (error) {
      this.handleError(error, 'findOne', { equipmentId: id });
    }
  }

  /**
   * 根据代码获取器材详情
   */
  @Get('code/:code')
  @ApiOperation({
    summary: '根据代码获取器材详情',
    description: '根据器材代码获取详细信息',
  })
  @ApiParam({
    name: 'code',
    description: '器材代码',
    example: 'DUMBBELLS_5KG',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findByCode(@Param('code') code: string): Promise<EquipmentDto> {
    try {
      this.logger.log(`根据代码获取器材详情: code=${code}`);
      return await this.equipmentService.findByCode(code);
    } catch (error) {
      this.handleError(error, 'findByCode', { equipmentCode: code });
    }
  }

  /**
   * 获取活跃器材列表
   */
  @Get('active/list')
  @ApiOperation({
    summary: '获取活跃器材列表',
    description: '获取所有活跃状态的器材，可按分类筛选',
  })
  @ApiQuery({
    name: 'category',
    required: false,
    description: '器材分类筛选',
    example: 'STRENGTH',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: [EquipmentDto],
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findActiveEquipment(@Query('category') category?: string): Promise<EquipmentDto[]> {
    try {
      this.logger.log(`获取活跃器材列表: category=${category}`);
      return await this.equipmentService.findActiveEquipment(category);
    } catch (error) {
      this.handleError(error, 'findActiveEquipment', { category });
    }
  }

  /**
   * 按分类获取器材
   */
  @Get('category/grouped')
  @ApiOperation({
    summary: '按分类获取器材',
    description: '获取按分类分组的器材列表',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: GetEquipmentByCategoryResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findEquipmentByCategory(): Promise<GetEquipmentByCategoryResponseDto> {
    try {
      this.logger.log('获取按分类分组的器材');
      return await this.equipmentService.findEquipmentByCategory();
    } catch (error) {
      this.handleError(error, 'findEquipmentByCategory');
    }
  }

  /**
   * 获取器材统计信息
   */
  @Get('stats/summary')
  @ApiOperation({
    summary: '获取器材统计信息',
    description: '获取器材总数、活跃数量、分类统计等信息',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: GetEquipmentStatsResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async getEquipmentStats(): Promise<GetEquipmentStatsResponseDto> {
    try {
      this.logger.log('获取器材统计信息');
      return await this.equipmentService.getEquipmentStats();
    } catch (error) {
      this.handleError(error, 'getEquipmentStats');
    }
  }

  /**
   * 创建器材
   */
  @Post()
  @ApiOperation({
    summary: '创建器材',
    description: '创建新的器材记录',
  })
  @ApiBody({ type: CreateEquipmentDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '创建成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.CONFLICT,
    description: '器材代码已存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async create(@Body() createDto: CreateEquipmentDto): Promise<EquipmentDto> {
    try {
      this.logger.log(`创建器材: ${JSON.stringify(createDto)}`);
      return await this.equipmentService.create(createDto);
    } catch (error) {
      this.handleError(error, 'create', { createDto });
    }
  }

  /**
   * 更新器材
   */
  @Put(':id')
  @ApiOperation({
    summary: '更新器材',
    description: '根据ID更新器材信息',
  })
  @ApiParam({
    name: 'id',
    description: '器材ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiBody({ type: UpdateEquipmentDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '更新成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.CONFLICT,
    description: '器材代码已存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async update(
    @Param('id') id: string,
    @Body() updateDto: UpdateEquipmentDto,
  ): Promise<EquipmentDto> {
    try {
      this.logger.log(`更新器材: id=${id}, data=${JSON.stringify(updateDto)}`);
      return await this.equipmentService.update(id, updateDto);
    } catch (error) {
      this.handleError(error, 'update', { equipmentId: id, updateDto });
    }
  }

  /**
   * 删除器材 (硬删除)
   */
  @Delete(':id')
  @ApiOperation({
    summary: '删除器材',
    description: '根据ID删除器材 (硬删除)',
  })
  @ApiParam({
    name: 'id',
    description: '器材ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '删除成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async remove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      this.logger.log(`删除器材: id=${id}`);
      return await this.equipmentService.remove(id);
    } catch (error) {
      this.handleError(error, 'remove', { equipmentId: id });
    }
  }

  /**
   * 软删除器材
   */
  @Put(':id/deactivate')
  @ApiOperation({
    summary: '软删除器材',
    description: '将器材设置为非活跃状态 (软删除)',
  })
  @ApiParam({
    name: 'id',
    description: '器材ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '软删除成功',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async softRemove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      this.logger.log(`软删除器材: id=${id}`);
      return await this.equipmentService.softRemove(id);
    } catch (error) {
      this.handleError(error, 'softRemove', { equipmentId: id });
    }
  }

  /**
   * 批量更新器材状态
   */
  @Put('batch/status')
  @ApiOperation({
    summary: '批量更新器材状态',
    description: '批量激活或禁用器材',
  })
  @ApiBody({ type: BatchUpdateEquipmentStatusDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '批量更新成功',
    schema: {
      type: 'object',
      properties: {
        count: {
          type: 'number',
          description: '更新的器材数量',
          example: 5,
        },
        message: {
          type: 'string',
          description: '操作结果消息',
          example: '成功激活了 5 个器材',
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '部分器材不存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async batchUpdateStatus(
    @Body() batchDto: BatchUpdateEquipmentStatusDto,
  ): Promise<{ count: number; message: string }> {
    try {
      this.logger.log(`批量更新器材状态: ${JSON.stringify(batchDto)}`);
      return await this.equipmentService.batchUpdateStatus(batchDto);
    } catch (error) {
      this.handleError(error, 'batchUpdateStatus', { batchDto });
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    this.logger.error(`Equipment Controller ${method} 失败:`, error.stack || error.message, {
      context,
      error: error.message,
    });

    if (error instanceof ResponseError) {
      switch (error.code) {
        case ErrorCodes.EQUIPMENT.NOT_FOUND.code:
          throw new NotFoundException(error.getUserMessage());

        case ErrorCodes.EQUIPMENT.CODE_EXISTS.code:
          throw new ConflictException(error.getUserMessage());

        case ErrorCodes.EQUIPMENT.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw new BadRequestException(error.getUserMessage());

        case ErrorCodes.EQUIPMENT.INACTIVE_EQUIPMENT.code:
          throw new BadRequestException(error.getUserMessage());

        case ErrorCodes.EQUIPMENT.CREATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.UPDATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.DELETE_FAILED.code:
        case ErrorCodes.EQUIPMENT.FETCH_FAILED.code:
        case ErrorCodes.EQUIPMENT.LIST_FAILED.code:
        case ErrorCodes.EQUIPMENT.COUNT_FAILED.code:
        default:
          this.logger.error(
            `未处理的器材错误: code=${error.code}, message=${error.message}`,
            error.stack,
          );
          throw new InternalServerErrorException('服务器内部错误');
      }
    }

    // 处理其他类型的错误
    if (error.name === 'ValidationError' || error.message?.includes('validation')) {
      throw new BadRequestException('请求参数验证失败');
    }

    throw new InternalServerErrorException('服务器内部错误');
  }
}
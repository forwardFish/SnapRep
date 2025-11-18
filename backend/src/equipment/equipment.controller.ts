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
  InternalServerErrorException,
  ConflictException,
  ValidationPipe,
  UsePipes,
  UseFilters,
} from '@nestjs/common';
import { EquipmentCategory as EquipmentCategoryEnum } from '../common/types/prisma-enums';
import { ApiTags, ApiOperation, ApiResponse, ApiParam, ApiBody, ApiQuery } from '@nestjs/swagger';
import { ResponseError } from '../exception/response-error';
import { EquipmentService } from './equipment.service';
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
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';
import { ResponseErrorFilter } from '../exception/response-error.filter';

/**
 * Equipment Controller
 * 提供器材相关的REST API接口
 */
@ApiTags('Equipment')
@Controller('rest/v1/equipment')
@UseFilters(ResponseErrorFilter)
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class EquipmentController {
  // private readonly logger = new Logger(EquipmentController.name);

  constructor(
    private readonly equipmentService: EquipmentService,
    private readonly supabaseApi: SupabaseApiService,
  ) {}

  /**
   * 使用 SupabaseApiService 获取器材列表
   * 绕过Prisma数据库连接问题
   */
  private async getEquipmentDirect(queryDto: GetEquipmentQueryDto): Promise<any> {
    try {
      const filters: Record<string, any> = {};

      if (queryDto.category) {
        filters.category = queryDto.category;
      }

      if (!queryDto.includeInactive) {
        filters.is_active = true;
      }

      const limit = queryDto.pageSize || 10;
      const offset = ((queryDto.page || 1) - 1) * limit;

      const equipment = await this.supabaseApi.get('equipment', filters, {
        limit,
        offset,
        orderBy: 'display_order.asc,created_at.asc',
      });

      return {
        data: equipment.map((item: any) => ({
          id: item.id,
          code: item.code,
          name: item.name,
          category: item.category,
          recognizable: item.recognizable || false,
          iconUrl: item.icon_url,
          imageUrl: item.image_url,
          displayOrder: item.display_order || 0,
          isActive: item.is_active,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
        })),
        pagination: {
          total: equipment.length, // 注意：这不是真实的总数
          page: queryDto.page || 1,
          pageSize: limit,
          totalPages: Math.ceil(equipment.length / limit),
          hasNextPage: equipment.length === limit,
          hasPreviousPage: (queryDto.page || 1) > 1,
        },
      };
    } catch (error) {
      logger.error('Supabase API call failed:', error);
      throw new InternalServerErrorException('Failed to fetch equipment');
    }
  }

  /**
   * 获取器材列表 (分页)
   */
  @Get()
  @ApiOperation({
    summary: '获取器材列表',
    description: '分页获取器材列表，支持按分类筛选和包含非活跃器材选项',
  })
  @ApiQuery({
    name: 'page',
    description: '页码，从1开始',
    required: false,
    example: 1,
    type: Number,
  })
  @ApiQuery({
    name: 'pageSize',
    description: '每页大小，最大100',
    required: false,
    example: 10,
    type: Number,
  })
  @ApiQuery({
    name: 'category',
    description: '器材分类筛选，支持小写输入如 furniture',
    required: false,
    enum: ['NONE', 'FURNITURE', 'WALL', 'BOTTLE', 'BAG', 'STAIRS', 'FABRIC', 'STICK', 'OUTDOOR', 'CREATIVE'],
    example: 'FURNITURE',
  })
  @ApiQuery({
    name: 'includeInactive',
    description: '是否包含非活跃器材',
    required: false,
    example: false,
    type: Boolean,
  })
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
      logger.info(`获取器材列表: ${JSON.stringify(queryDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');
      return await this.getEquipmentDirect(queryDto);
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
    description: '器材未找到',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findOne(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`获取器材详情: id=${id}`);
      logger.info('Using direct Supabase API due to database connection issue');

      const item = await this.supabaseApi.getById('equipment', id);

      if (!item) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      return {
        id: item.id,
        code: item.code,
        name: item.name,
        category: item.category,
        recognizable: item.recognizable || false,
        iconUrl: item.icon_url,
        imageUrl: item.image_url,
        displayOrder: item.display_order || 0,
        isActive: item.is_active,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      };
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
    description: '器材未找到',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async findByCode(@Param('code') code: string): Promise<EquipmentDto> {
    try {
      logger.info(`根据代码获取器材详情: code=${code}`);
      logger.info('Using direct Supabase API due to database connection issue');

      const item = await this.supabaseApi.getByField('equipment', 'code', code);

      if (!item) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentCode: code,
        });
      }

      return {
        id: item.id,
        code: item.code,
        name: item.name,
        category: item.category,
        recognizable: item.recognizable || false,
        iconUrl: item.icon_url,
        imageUrl: item.image_url,
        displayOrder: item.display_order || 0,
        isActive: item.is_active,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      };
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
    description: '获取所有活跃状态的器材列表',
  })
  @ApiQuery({
    name: 'category',
    description: '器材分类',
    required: false,
    enum: EquipmentCategoryEnum,
    example: EquipmentCategoryEnum.FURNITURE,
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
      logger.info(`获取活跃器材列表: category=${category}`);
      logger.info('Using direct Supabase API due to database connection issue');

      const filters: Record<string, any> = {
        is_active: true,
      };

      const cat = category?.toString().toUpperCase();
      if (cat) {
        const allowed = Object.values(EquipmentCategoryEnum);
        if (!allowed.includes(cat as EquipmentCategoryEnum)) {
          throw new BadRequestException('category 必须是以下之一: ' + allowed.join(', '));
        }
        filters.category = cat;
      }

      const equipment = await this.supabaseApi.get('equipment', filters, {
        orderBy: 'display_order.asc,created_at.asc',
      });

      return equipment.map((item: any) => ({
        id: item.id,
        code: item.code,
        name: item.name,
        category: item.category,
        recognizable: item.recognizable || false,
        iconUrl: item.icon_url,
        imageUrl: item.image_url,
        displayOrder: item.display_order || 0,
        isActive: item.is_active,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      }));
    } catch (error) {
      this.handleError(error, 'findActiveEquipment', { category });
    }
  }

  /**
   * 按分类获取器材
   */
  @Get('category/grouped')
  @ApiOperation({
    summary: '获取分组器材列表',
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
      logger.info('获取按分类分组的器材');
      logger.info('Using direct Supabase API due to database connection issue');

      const allEquipment = await this.supabaseApi.get('equipment',
        { is_active: true },
        { orderBy: 'display_order.asc,created_at.asc' }
      );

      const groupedData: Record<string, any[]> = {};

      allEquipment.forEach((item: any) => {
        const category = item.category || 'NONE';
        if (!groupedData[category]) {
          groupedData[category] = [];
        }

        groupedData[category].push({
          id: item.id,
          code: item.code,
          name: item.name,
          category: item.category,
          recognizable: item.recognizable || false,
          iconUrl: item.icon_url,
          imageUrl: item.image_url,
          displayOrder: item.display_order || 0,
          isActive: item.is_active,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
        });
      });

      return { data: groupedData };
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
      logger.info('获取器材统计信息');
      logger.info('Using direct Supabase API due to database connection issue');

      // 获取所有器材
      const allEquipment = await this.supabaseApi.get('equipment', {}, {
        orderBy: 'category.asc,display_order.asc',
      });

      // 计算总数和活跃数
      const total = allEquipment.length;
      const active = allEquipment.filter((item: any) => item.is_active).length;
      const inactive = total - active;

      // 按分类统计
      const categoryStats: Record<string, any> = {};
      allEquipment.forEach((item: any) => {
        const category = item.category || 'NONE';
        if (!categoryStats[category]) {
          categoryStats[category] = {
            category,
            count: 0,
            items: [],
          };
        }
        categoryStats[category].count++;
        categoryStats[category].items.push({
          id: item.id,
          code: item.code,
          name: item.name,
        });
      });

      return {
        total,
        active,
        inactive,
        categories: Object.values(categoryStats),
      };
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
      logger.info(`创建器材: ${JSON.stringify(createDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查代码是否已存在
      const existing = await this.supabaseApi.getByField('equipment', 'code', createDto.code);
      if (existing) {
         throw new ResponseError(ErrorCodes.EQUIPMENT.ALREADY_EXISTS, undefined, {
          equipmentCode: createDto.code,
        });
      }

      // 生成CUID ID
      const cuidId = `cuid_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

      // 创建器材数据
      const createData = {
        id: cuidId,
        code: createDto.code,
        name: createDto.name,
        // description: createDto.description || null, // 数据库中没有这个字段，先注释掉
        category: createDto.category || null,
        recognizable: false, // 默认值，DTO中没有此字段
        recognition_labels: [], // Supabase中的字段名是snake_case
        recognition_confidence: 0.85, // 默认置信度
        icon_url: createDto.imageUrl || 'https://example.com/default-icon.jpg', // 使用imageUrl作为iconUrl或默认值
        image_url: createDto.imageUrl || null,
        display_order: createDto.displayOrder || 0,
        is_active: createDto.isActive !== undefined ? createDto.isActive : true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      const newItem = await this.supabaseApi.post('equipment', createData);

      return {
        id: newItem.id,
        code: newItem.code,
        name: newItem.name,
        // description: newItem.description, // 数据库中没有这个字段
        category: newItem.category,
        recognizable: newItem.recognizable || false,
        iconUrl: newItem.icon_url,
        imageUrl: newItem.image_url,
        displayOrder: newItem.display_order || 0,
        isActive: newItem.is_active,
        createdAt: newItem.created_at,
        updatedAt: newItem.updated_at,
      };
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
    description: '器材未找到',
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
      logger.info(`更新器材: id=${id}, data=${JSON.stringify(updateDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查器材是否存在
      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 如果要更新code，检查是否与其他记录冲突
      if (updateDto.code && updateDto.code !== existing.code) {
        const codeConflict = await this.supabaseApi.getByField('equipment', 'code', updateDto.code);
        if (codeConflict) {
          throw new ResponseError(ErrorCodes.EQUIPMENT.ALREADY_EXISTS, undefined, {
            equipmentCode: updateDto.code,
          });
        }
      }

      // 创建更新数据
      const updateData: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateDto.code) updateData.code = updateDto.code;
      if (updateDto.name) updateData.name = updateDto.name;
      // if (updateDto.description !== undefined) updateData.description = updateDto.description; // 数据库中没有此字段
      if (updateDto.category !== undefined) updateData.category = updateDto.category;
      if (updateDto.imageUrl !== undefined) {
        updateData.image_url = updateDto.imageUrl;
        updateData.icon_url = updateDto.imageUrl; // 同时更新icon_url
      }
      if (updateDto.displayOrder !== undefined) updateData.display_order = updateDto.displayOrder;
      if (updateDto.isActive !== undefined) updateData.is_active = updateDto.isActive;

      const updatedItem = await this.supabaseApi.patch('equipment', id, updateData);

      return {
        id: updatedItem.id,
        code: updatedItem.code,
        name: updatedItem.name,
        // description: updatedItem.description, // 数据库中没有此字段
        category: updatedItem.category,
        recognizable: updatedItem.recognizable || false,
        iconUrl: updatedItem.icon_url,
        imageUrl: updatedItem.image_url,
        displayOrder: updatedItem.display_order || 0,
        isActive: updatedItem.is_active,
        createdAt: updatedItem.created_at,
        updatedAt: updatedItem.updated_at,
      };
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
    description: '器材未找到',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async remove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`删除器材: id=${id}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查器材是否存在
      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 执行硬删除
      await this.supabaseApi.delete('equipment', id);

      // 返回被删除的器材信息
      return {
        id: existing.id,
        code: existing.code,
        name: existing.name,
        // description: existing.description, // 数据库中没有此字段
        category: existing.category,
        recognizable: existing.recognizable || false,
        iconUrl: existing.icon_url,
        imageUrl: existing.image_url,
        displayOrder: existing.display_order || 0,
        isActive: existing.is_active,
        createdAt: existing.created_at,
        updatedAt: existing.updated_at,
      };
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
    description: '将器材设置为非活跃状态(软删除)',
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
    description: '器材未找到',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async softRemove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`软删除器材: id=${id}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查器材是否存在
      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 执行软删除 - 设置 is_active = false
      const updateData = {
        is_active: false,
        updated_at: new Date().toISOString(),
      };

      const updatedItem = await this.supabaseApi.patch('equipment', id, updateData);

      return {
        id: updatedItem.id,
        code: updatedItem.code,
        name: updatedItem.name,
        // description: updatedItem.description, // 数据库中没有此字段
        category: updatedItem.category,
        recognizable: updatedItem.recognizable || false,
        iconUrl: updatedItem.icon_url,
        imageUrl: updatedItem.image_url,
        displayOrder: updatedItem.display_order || 0,
        isActive: updatedItem.is_active,
        createdAt: updatedItem.created_at,
        updatedAt: updatedItem.updated_at,
      };
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
          description: '更新成功的器材数量',
          example: 5,
        },
        message: {
          type: 'string',
          description: '操作结果消息',
          example: '成功更新 5 个器材状态',
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
    description: '器材未找到',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async batchUpdateStatus(
    @Body() batchDto: BatchUpdateEquipmentStatusDto,
  ): Promise<{ count: number; message: string }> {
    try {
      logger.info(`批量更新器材状态: ${JSON.stringify(batchDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      if (!batchDto.ids || batchDto.ids.length === 0) {
        throw new BadRequestException('Equipment IDs are required');
      }

      let successCount = 0;
      const updateData = {
        is_active: batchDto.isActive,
        updated_at: new Date().toISOString(),
      };

      // 批量更新每个器材的状态
      for (const id of batchDto.ids) {
        try {
          // 检查器材是否存在
          const existing = await this.supabaseApi.getById('equipment', id);
          if (existing) {
            await this.supabaseApi.patch('equipment', id, updateData);
            successCount++;
          } else {
            logger.warn(`Equipment with ID ${id} not found`);
          }
        } catch (error) {
          logger.error(`Failed to update equipment ${id}: ${error.message}`);
        }
      }

      const message = `Successfully updated ${successCount} out of ${batchDto.ids.length} equipment items`;
      logger.info(message);

      return {
        count: successCount,
        message,
      };
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
    logger.error(`Equipment Controller ${method} 失败:`, error.stack || error.message, {
      context,
      error: error.message,
    });

    if (error instanceof ResponseError) {
      switch (error.code) {
        case ErrorCodes.EQUIPMENT.NOT_FOUND.code:
          throw error; // 直接抛出 ResponseError 而不是转换为 NotFoundException

        case ErrorCodes.EQUIPMENT.CODE_EXISTS.code:
          throw error; // 直接抛出 ResponseError

        case ErrorCodes.EQUIPMENT.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw error; // 直接抛出 ResponseError

        case ErrorCodes.EQUIPMENT.INACTIVE_EQUIPMENT.code:
          throw error; // 直接抛出 ResponseError

        case ErrorCodes.EQUIPMENT.CREATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.UPDATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.DELETE_FAILED.code:
        case ErrorCodes.EQUIPMENT.FETCH_FAILED.code:
        case ErrorCodes.EQUIPMENT.LIST_FAILED.code:
        case ErrorCodes.EQUIPMENT.COUNT_FAILED.code:
        default:
          logger.error(
            `未处理的器材错误: code=${error.code}, message=${error.message}`,
            error.stack,
          );
          throw error;
          // throw new InternalServerErrorException('服务器内部错误');
      }
    }

    // 处理其他类型的错误
    if (error.name === 'ValidationError' || error.message?.includes('validation')) {
      throw new BadRequestException('请求参数验证失败');
    }
    throw error;
    // throw new InternalServerErrorException('服务器内部错误');
  }
}
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
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
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
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';
import { ResponseErrorFilter } from '../exception/response-error.filter';

/**
 * Equipment Controller 绫? * 鎻愪緵鍣ㄦ潗鐩稿叧鐨凴EST API鎺ュ彛
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
   * 浣跨敤 SupabaseApiService 鑾峰彇鍣ㄦ潗鍒楄〃
   * 缁曡繃Prisma鏁版嵁搴撹繛鎺ラ棶棰?   */
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
          total: equipment.length, // 娉ㄦ剰锛氳繖涓嶆槸鐪熷疄鐨勬€绘暟
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
   * 鑾峰彇鍣ㄦ潗鍒楄〃 (鍒嗛〉)
   */
  @Get()
  @ApiOperation({
    summary: '鑾峰彇鍣ㄦ潗鍒楄〃',
    description: '鍒嗛〉鑾峰彇鍣ㄦ潗鍒楄〃锛屾敮鎸佹寜鍒嗙被绛涢€夊拰鍖呭惈闈炴椿璺冨櫒鏉?,
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鑾峰彇鎴愬姛',
    type: GetEquipmentResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '璇锋眰鍙傛暟閿欒',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async findAll(@Query() queryDto: GetEquipmentQueryDto): Promise<GetEquipmentResponseDto> {
    try {
      logger.info(`鑾峰彇鍣ㄦ潗鍒楄〃: ${JSON.stringify(queryDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');
      return await this.getEquipmentDirect(queryDto);
    } catch (error) {
      this.handleError(error, 'findAll', { queryDto });
    }
  }

  /**
   * 鏍规嵁ID鑾峰彇鍣ㄦ潗璇︽儏
   */
  @Get(':id')
  @ApiOperation({
    summary: '鑾峰彇鍣ㄦ潗璇︽儏',
    description: '鏍规嵁鍣ㄦ潗ID鑾峰彇璇︾粏淇℃伅',
  })
  @ApiParam({
    name: 'id',
    description: '鍣ㄦ潗ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鑾峰彇鎴愬姛',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async findOne(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`鑾峰彇鍣ㄦ潗璇︽儏: id=${id}`);
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
   * 鏍规嵁浠ｇ爜鑾峰彇鍣ㄦ潗璇︽儏
   */
  @Get('code/:code')
  @ApiOperation({
    summary: '鏍规嵁浠ｇ爜鑾峰彇鍣ㄦ潗璇︽儏',
    description: '鏍规嵁鍣ㄦ潗浠ｇ爜鑾峰彇璇︾粏淇℃伅',
  })
  @ApiParam({
    name: 'code',
    description: '鍣ㄦ潗浠ｇ爜',
    example: 'DUMBBELLS_5KG',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鑾峰彇鎴愬姛',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async findByCode(@Param('code') code: string): Promise<EquipmentDto> {
    try {
      logger.info(`鏍规嵁浠ｇ爜鑾峰彇鍣ㄦ潗璇︽儏: code=${code}`);
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
   * 鑾峰彇娲昏穬鍣ㄦ潗鍒楄〃
   */
  @Get('active/list')
  @ApiOperation({
    summary: '鑾峰彇娲昏穬鍣ㄦ潗鍒楄〃',
    description: '鑾峰彇鎵€鏈夋椿璺冪姸鎬佺殑鍣ㄦ潗锛屽彲鎸夊垎绫荤瓫閫?,
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
    description: '鑾峰彇鎴愬姛',
    type: [EquipmentDto],
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async findActiveEquipment(@Query('category') category?: string): Promise<EquipmentDto[]> {
    try {
      logger.info(`鑾峰彇娲昏穬鍣ㄦ潗鍒楄〃: category=${category}`);
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
   * 鎸夊垎绫昏幏鍙栧櫒鏉?   */
  @Get('category/grouped')
  @ApiOperation({
    summary: '鎸夊垎绫昏幏鍙栧櫒鏉?,
    description: '鑾峰彇鎸夊垎绫诲垎缁勭殑鍣ㄦ潗鍒楄〃',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鑾峰彇鎴愬姛',
    type: GetEquipmentByCategoryResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async findEquipmentByCategory(): Promise<GetEquipmentByCategoryResponseDto> {
    try {
      logger.info('鑾峰彇鎸夊垎绫诲垎缁勭殑鍣ㄦ潗');
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
   * 鑾峰彇鍣ㄦ潗缁熻淇℃伅
   */
  @Get('stats/summary')
  @ApiOperation({
    summary: '鑾峰彇鍣ㄦ潗缁熻淇℃伅',
    description: '鑾峰彇鍣ㄦ潗鎬绘暟銆佹椿璺冩暟閲忋€佸垎绫荤粺璁＄瓑淇℃伅',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鑾峰彇鎴愬姛',
    type: GetEquipmentStatsResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async getEquipmentStats(): Promise<GetEquipmentStatsResponseDto> {
    try {
      logger.info('鑾峰彇鍣ㄦ潗缁熻淇℃伅');
      logger.info('Using direct Supabase API due to database connection issue');

      // 鑾峰彇鎵€鏈夊櫒鏉?      const allEquipment = await this.supabaseApi.get('equipment', {}, {
        orderBy: 'category.asc,display_order.asc',
      });

      // 璁＄畻鎬绘暟鍜屾椿璺冩暟
      const total = allEquipment.length;
      const active = allEquipment.filter((item: any) => item.is_active).length;
      const inactive = total - active;

      // 鎸夊垎绫荤粺璁?      const categoryStats: Record<string, any> = {};
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
   * 鍒涘缓鍣ㄦ潗
   */
  @Post()
  @ApiOperation({
    summary: '鍒涘缓鍣ㄦ潗',
    description: '鍒涘缓鏂扮殑鍣ㄦ潗璁板綍',
  })
  @ApiBody({ type: CreateEquipmentDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '鍒涘缓鎴愬姛',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '璇锋眰鍙傛暟閿欒',
  })
  @ApiResponse({
    status: HttpStatus.CONFLICT,
    description: '鍣ㄦ潗浠ｇ爜宸插瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async create(@Body() createDto: CreateEquipmentDto): Promise<EquipmentDto> {
    try {
      logger.info(`鍒涘缓鍣ㄦ潗: ${JSON.stringify(createDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 妫€鏌ヤ唬鐮佹槸鍚﹀凡瀛樺湪
      const existing = await this.supabaseApi.getByField('equipment', 'code', createDto.code);
      if (existing) {
         throw new ResponseError(ErrorCodes.EQUIPMENT.ALREADY_EXISTS, undefined, {
          equipmentCode: createDto.code,
        });
      }

      // 鐢熸垚CUID ID
      const cuidId = `cuid_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

      // 鍒涘缓鍣ㄦ潗鏁版嵁
      const createData = {
        id: cuidId,
        code: createDto.code,
        name: createDto.name,
        // description: createDto.description || null, // 鏁版嵁搴撲腑娌℃湁杩欎釜瀛楁锛屽厛娉ㄩ噴鎺?        category: createDto.category || null,
        recognizable: false, // 榛樿鍊硷紝DTO涓病鏈夋瀛楁
        recognition_labels: [], // Supabase涓殑瀛楁鍚嶆槸snake_case
        recognition_confidence: 0.85, // 榛樿缃俊搴?        icon_url: createDto.imageUrl || 'https://example.com/default-icon.jpg', // 浣跨敤imageUrl浣滀负iconUrl鎴栭粯璁ゅ€?        image_url: createDto.imageUrl || null,
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
        // description: newItem.description, // 鏁版嵁搴撲腑娌℃湁杩欎釜瀛楁
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
   * 鏇存柊鍣ㄦ潗
   */
  @Put(':id')
  @ApiOperation({
    summary: '鏇存柊鍣ㄦ潗',
    description: '鏍规嵁ID鏇存柊鍣ㄦ潗淇℃伅',
  })
  @ApiParam({
    name: 'id',
    description: '鍣ㄦ潗ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiBody({ type: UpdateEquipmentDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鏇存柊鎴愬姛',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '璇锋眰鍙傛暟閿欒',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.CONFLICT,
    description: '鍣ㄦ潗浠ｇ爜宸插瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async update(
    @Param('id') id: string,
    @Body() updateDto: UpdateEquipmentDto,
  ): Promise<EquipmentDto> {
    try {
      logger.info(`鏇存柊鍣ㄦ潗: id=${id}, data=${JSON.stringify(updateDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 妫€鏌ュ櫒鏉愭槸鍚﹀瓨鍦?      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 濡傛灉瑕佹洿鏂癱ode锛屾鏌ユ槸鍚︿笌鍏朵粬璁板綍鍐茬獊
      if (updateDto.code && updateDto.code !== existing.code) {
        const codeConflict = await this.supabaseApi.getByField('equipment', 'code', updateDto.code);
        if (codeConflict) {
          throw new ResponseError(ErrorCodes.EQUIPMENT.ALREADY_EXISTS, undefined, {
            equipmentCode: updateDto.code,
          });
        }
      }

      // 鍒涘缓鏇存柊鏁版嵁
      const updateData: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateDto.code) updateData.code = updateDto.code;
      if (updateDto.name) updateData.name = updateDto.name;
      // if (updateDto.description !== undefined) updateData.description = updateDto.description; // 鏁版嵁搴撲腑娌℃湁姝ゅ瓧娈?      if (updateDto.category !== undefined) updateData.category = updateDto.category;
      if (updateDto.imageUrl !== undefined) {
        updateData.image_url = updateDto.imageUrl;
        updateData.icon_url = updateDto.imageUrl; // 鍚屾椂鏇存柊icon_url
      }
      if (updateDto.displayOrder !== undefined) updateData.display_order = updateDto.displayOrder;
      if (updateDto.isActive !== undefined) updateData.is_active = updateDto.isActive;

      const updatedItem = await this.supabaseApi.patch('equipment', id, updateData);

      return {
        id: updatedItem.id,
        code: updatedItem.code,
        name: updatedItem.name,
        // description: updatedItem.description, // 鏁版嵁搴撲腑娌℃湁姝ゅ瓧娈?        category: updatedItem.category,
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
   * 鍒犻櫎鍣ㄦ潗 (纭垹闄?
   */
  @Delete(':id')
  @ApiOperation({
    summary: '鍒犻櫎鍣ㄦ潗',
    description: '鏍规嵁ID鍒犻櫎鍣ㄦ潗 (纭垹闄?',
  })
  @ApiParam({
    name: 'id',
    description: '鍣ㄦ潗ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鍒犻櫎鎴愬姛',
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async remove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`鍒犻櫎鍣ㄦ潗: id=${id}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 妫€鏌ュ櫒鏉愭槸鍚﹀瓨鍦?      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 鎵ц纭垹闄?      await this.supabaseApi.delete('equipment', id);

      // 杩斿洖琚垹闄ょ殑鍣ㄦ潗淇℃伅
      return {
        id: existing.id,
        code: existing.code,
        name: existing.name,
        // description: existing.description, // 鏁版嵁搴撲腑娌℃湁姝ゅ瓧娈?        category: existing.category,
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
   * 杞垹闄ゅ櫒鏉?   */
  @Put(':id/deactivate')
  @ApiOperation({
    summary: '杞垹闄ゅ櫒鏉?,
    description: '灏嗗櫒鏉愯缃负闈炴椿璺冪姸鎬?(杞垹闄?',
  })
  @ApiParam({
    name: 'id',
    description: '鍣ㄦ潗ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '杞垹闄ゆ垚鍔?,
    type: EquipmentDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async softRemove(@Param('id') id: string): Promise<EquipmentDto> {
    try {
      logger.info(`杞垹闄ゅ櫒鏉? id=${id}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 妫€鏌ュ櫒鏉愭槸鍚﹀瓨鍦?      const existing = await this.supabaseApi.getById('equipment', id);
      if (!existing) {
        throw new ResponseError(ErrorCodes.EQUIPMENT.NOT_FOUND, undefined, {
          equipmentId: id,
        });
      }

      // 鎵ц杞垹闄?- 璁剧疆 is_active = false
      const updateData = {
        is_active: false,
        updated_at: new Date().toISOString(),
      };

      const updatedItem = await this.supabaseApi.patch('equipment', id, updateData);

      return {
        id: updatedItem.id,
        code: updatedItem.code,
        name: updatedItem.name,
        // description: updatedItem.description, // 鏁版嵁搴撲腑娌℃湁姝ゅ瓧娈?        category: updatedItem.category,
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
   * 鎵归噺鏇存柊鍣ㄦ潗鐘舵€?   */
  @Put('batch/status')
  @ApiOperation({
    summary: '鎵归噺鏇存柊鍣ㄦ潗鐘舵€?,
    description: '鎵归噺婵€娲绘垨绂佺敤鍣ㄦ潗',
  })
  @ApiBody({ type: BatchUpdateEquipmentStatusDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '鎵归噺鏇存柊鎴愬姛',
    schema: {
      type: 'object',
      properties: {
        count: {
          type: 'number',
          description: '鏇存柊鐨勫櫒鏉愭暟閲?,
          example: 5,
        },
        message: {
          type: 'string',
          description: '鎿嶄綔缁撴灉娑堟伅',
          example: '鎴愬姛婵€娲讳簡 5 涓櫒鏉?,
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '璇锋眰鍙傛暟閿欒',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '閮ㄥ垎鍣ㄦ潗涓嶅瓨鍦?,
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?,
  })
  async batchUpdateStatus(
    @Body() batchDto: BatchUpdateEquipmentStatusDto,
  ): Promise<{ count: number; message: string }> {
    try {
      logger.info(`鎵归噺鏇存柊鍣ㄦ潗鐘舵€? ${JSON.stringify(batchDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      if (!batchDto.ids || batchDto.ids.length === 0) {
        throw new BadRequestException('Equipment IDs are required');
      }

      let successCount = 0;
      const updateData = {
        is_active: batchDto.isActive,
        updated_at: new Date().toISOString(),
      };

      // 鎵归噺鏇存柊姣忎釜鍣ㄦ潗鐨勭姸鎬?      for (const id of batchDto.ids) {
        try {
          // 妫€鏌ュ櫒鏉愭槸鍚﹀瓨鍦?          const existing = await this.supabaseApi.getById('equipment', id);
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
   * 缁熶竴閿欒澶勭悊鏂规硶
   * @param error 閿欒瀵硅薄
   * @param method 鏂规硶鍚?   * @param context 涓婁笅鏂囦俊鎭?   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`Equipment Controller ${method} 澶辫触:`, error.stack || error.message, {
      context,
      error: error.message,
    });

    if (error instanceof ResponseError) {
      switch (error.code) {
        case ErrorCodes.EQUIPMENT.NOT_FOUND.code:
          throw error; // 鐩存帴鎶涘嚭 ResponseError 鑰屼笉鏄浆鎹负 NotFoundException

        case ErrorCodes.EQUIPMENT.CODE_EXISTS.code:
          throw error; // 鐩存帴鎶涘嚭 ResponseError

        case ErrorCodes.EQUIPMENT.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw error; // 鐩存帴鎶涘嚭 ResponseError

        case ErrorCodes.EQUIPMENT.INACTIVE_EQUIPMENT.code:
          throw error; // 鐩存帴鎶涘嚭 ResponseError

        case ErrorCodes.EQUIPMENT.CREATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.UPDATE_FAILED.code:
        case ErrorCodes.EQUIPMENT.DELETE_FAILED.code:
        case ErrorCodes.EQUIPMENT.FETCH_FAILED.code:
        case ErrorCodes.EQUIPMENT.LIST_FAILED.code:
        case ErrorCodes.EQUIPMENT.COUNT_FAILED.code:
        default:
          logger.error(
            `鏈鐞嗙殑鍣ㄦ潗閿欒: code=${error.code}, message=${error.message}`,
            error.stack,
          );
          throw error; 
          // throw new InternalServerErrorException('鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?);
      }
    }

    // 澶勭悊鍏朵粬绫诲瀷鐨勯敊璇?    if (error.name === 'ValidationError' || error.message?.includes('validation')) {
      throw new BadRequestException('璇锋眰鍙傛暟楠岃瘉澶辫触');
    }
    throw error; 
    // throw new InternalServerErrorException('鏈嶅姟鍣ㄥ唴閮ㄩ敊璇?);
  }
}



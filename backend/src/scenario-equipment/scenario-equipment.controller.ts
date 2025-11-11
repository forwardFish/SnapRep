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
  NotFoundException,
  ValidationPipe,
  UsePipes,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import {
  CreateScenarioEquipmentDto,
  UpdateScenarioEquipmentDto,
  BatchCreateScenarioEquipmentDto,
  ScenarioEquipmentResponseDto,
  EquipmentWithAssociationDto,
  ScenarioWithAssociationDto,
} from './dto';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';

/**
 * ScenarioEquipment Controller 类
 * 提供场景-器材关联关系的REST API接口
 * 使用 SupabaseApiService 直接操作数据库，绕过 Prisma 连接问题
 */
@ApiTags('ScenarioEquipment')
@Controller('rest/v1/scenario-equipment')
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class ScenarioEquipmentController {
  private readonly logger = new Logger(ScenarioEquipmentController.name);

  constructor(private readonly supabaseApi: SupabaseApiService) {
    logger.info('ScenarioEquipmentController initialized with SupabaseApiService');
  }

  /**
   * 数据映射：将 Supabase 数据转换为 DTO 格式
   */
  private mapToResponseDto(item: any): ScenarioEquipmentResponseDto {
    return {
      scenarioId: item.scenario_id,
      equipmentId: item.equipment_id,
      isCommon: item.is_common,
      createdAt: item.created_at ? new Date(item.created_at) : new Date(),
      scenario: item.scenario || undefined,
      equipment: item.equipment || undefined,
    };
  }

  /**
   * 检查关联是否存在的辅助方法
   */
  private async checkAssociationExists(scenarioId: string, equipmentId: string): Promise<boolean> {
    try {
      const existing = await this.supabaseApi.get('scenario_equipment', {
        scenario_id: scenarioId,
        equipment_id: equipmentId,
      }, { limit: 1 });

      return existing && existing.length > 0;
    } catch (error) {
      logger.error(`检查关联失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 创建场景-器材关联
   */
  @Post()
  @ApiOperation({
    summary: '创建场景-器材关联',
    description: '在指定场景和器材之间创建关联关系',
  })
  @ApiBody({ type: CreateScenarioEquipmentDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '关联创建成功',
    type: ScenarioEquipmentResponseDto,
  })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: '参数错误' })
  @ApiResponse({ status: HttpStatus.CONFLICT, description: '关联已存在' })
  async create(@Body() createDto: CreateScenarioEquipmentDto): Promise<ScenarioEquipmentResponseDto> {
    try {
      logger.info(`创建场景-器材关联: ${JSON.stringify(createDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查关联是否已存在
      const exists = await this.checkAssociationExists(createDto.scenarioId, createDto.equipmentId);
      if (exists) {
        throw new ResponseError(ErrorCodes.SCENARIO_EQUIPMENT.ALREADY_EXISTS, undefined, {
          scenarioId: createDto.scenarioId,
          equipmentId: createDto.equipmentId,
        });
      }

      // 验证场景和器材是否存在
      const [scenario, equipment] = await Promise.all([
        this.supabaseApi.getById('scenarios', createDto.scenarioId),
        this.supabaseApi.getById('equipment', createDto.equipmentId),
      ]);

      if (!scenario) {
        throw new BadRequestException(`Scenario with ID ${createDto.scenarioId} not found`);
      }
      if (!equipment) {
        throw new BadRequestException(`Equipment with ID ${createDto.equipmentId} not found`);
      }

      // 创建关联数据
      const createData = {
        scenario_id: createDto.scenarioId,
        equipment_id: createDto.equipmentId,
        is_common: createDto.isCommon !== undefined ? createDto.isCommon : true,
        created_at: new Date().toISOString(),
      };

      const newAssociation = await this.supabaseApi.post('scenario_equipment', createData);

      logger.info(`场景-器材关联创建成功: ${createDto.scenarioId} - ${createDto.equipmentId}`);
      return this.mapToResponseDto(newAssociation);
    } catch (error) {
      this.handleError(error, 'create', { createDto });
    }
  }

  /**
   * 批量创建场景-器材关联
   */
  @Post('batch')
  @ApiOperation({
    summary: '批量创建场景-器材关联',
    description: '为一个场景批量关联多个器材',
  })
  @ApiBody({ type: BatchCreateScenarioEquipmentDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '批量关联创建成功',
  })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: '参数错误' })
  async createBatch(@Body() batchCreateDto: BatchCreateScenarioEquipmentDto): Promise<{
    success: number;
    failed: number;
    results: Array<{ equipmentId: string; status: string; message?: string }>;
  }> {
    try {
      logger.info(`批量创建场景-器材关联: ${JSON.stringify(batchCreateDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      if (!batchCreateDto.equipmentIds || batchCreateDto.equipmentIds.length === 0) {
        throw new BadRequestException('Equipment IDs are required');
      }

      // 验证场景是否存在
      const scenario = await this.supabaseApi.getById('scenarios', batchCreateDto.scenarioId);
      if (!scenario) {
        throw new BadRequestException(`Scenario with ID ${batchCreateDto.scenarioId} not found`);
      }

      const results = [];
      let successCount = 0;
      let failedCount = 0;

      for (const equipmentId of batchCreateDto.equipmentIds) {
        try {
          // 检查器材是否存在
          const equipment = await this.supabaseApi.getById('equipment', equipmentId);
          if (!equipment) {
            results.push({
              equipmentId,
              status: 'failed',
              message: `Equipment with ID ${equipmentId} not found`,
            });
            failedCount++;
            continue;
          }

          // 检查关联是否已存在
          const exists = await this.checkAssociationExists(batchCreateDto.scenarioId, equipmentId);
          if (exists) {
            results.push({
              equipmentId,
              status: 'skipped',
              message: 'Association already exists',
            });
            continue;
          }

          // 创建关联
          const createData = {
            scenario_id: batchCreateDto.scenarioId,
            equipment_id: equipmentId,
            is_common: batchCreateDto.isCommon !== undefined ? batchCreateDto.isCommon : true,
            created_at: new Date().toISOString(),
          };

          await this.supabaseApi.post('scenario_equipment', createData);
          results.push({
            equipmentId,
            status: 'success',
          });
          successCount++;
        } catch (error) {
          logger.error(`Failed to create association for equipment ${equipmentId}: ${error.message}`);
          results.push({
            equipmentId,
            status: 'failed',
            message: error.message,
          });
          failedCount++;
        }
      }

      logger.info(`批量创建场景-器材关联完成: 成功=${successCount}, 失败=${failedCount}`);

      return {
        success: successCount,
        failed: failedCount,
        results,
      };
    } catch (error) {
      this.handleError(error, 'createBatch', { batchCreateDto });
    }
  }

  /**
   * 更新关联关系的常见性
   */
  @Put(':scenarioId/:equipmentId')
  @ApiOperation({
    summary: '更新关联关系',
    description: '更新场景-器材关联的常见性属性',
  })
  @ApiParam({ name: 'scenarioId', description: '场景ID' })
  @ApiParam({ name: 'equipmentId', description: '器材ID' })
  @ApiBody({ type: UpdateScenarioEquipmentDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '关联更新成功',
    type: ScenarioEquipmentResponseDto,
  })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: '关联不存在' })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: '参数错误' })
  async update(
    @Param('scenarioId') scenarioId: string,
    @Param('equipmentId') equipmentId: string,
    @Body() updateDto: UpdateScenarioEquipmentDto
  ): Promise<ScenarioEquipmentResponseDto> {
    try {
      logger.info(`更新场景-器材关联: ${scenarioId} - ${equipmentId}, data=${JSON.stringify(updateDto)}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 检查关联是否存在
      const existing = await this.supabaseApi.get('scenario_equipment', {
        scenario_id: scenarioId,
        equipment_id: equipmentId,
      }, { limit: 1 });

      if (!existing || existing.length === 0) {
        throw new NotFoundException(`Association between scenario ${scenarioId} and equipment ${equipmentId} not found`);
      }

      // 构造更新数据
      const updateData = {
        is_common: updateDto.isCommon,
      };

      // 执行更新（通过先删除后创建来模拟更新，因为 Supabase 复合主键的限制）
      await this.supabaseApi.delete('scenario_equipment', existing[0].id);

      const newData = {
        ...existing[0],
        ...updateData,
        id: undefined, // 让 Supabase 自动生成新 ID
      };

      const updatedAssociation = await this.supabaseApi.post('scenario_equipment', newData);

      logger.info(`场景-器材关联更新成功: ${scenarioId} - ${equipmentId}`);
      return this.mapToResponseDto(updatedAssociation);
    } catch (error) {
      this.handleError(error, 'update', { scenarioId, equipmentId, updateDto });
    }
  }

  /**
   * 删除场景-器材关联
   */
  @Delete(':scenarioId/:equipmentId')
  @ApiOperation({
    summary: '删除场景-器材关联',
    description: '删除指定的场景-器材关联关系',
  })
  @ApiParam({ name: 'scenarioId', description: '场景ID' })
  @ApiParam({ name: 'equipmentId', description: '器材ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '关联删除成功',
    type: ScenarioEquipmentResponseDto,
  })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: '关联不存在' })
  async remove(
    @Param('scenarioId') scenarioId: string,
    @Param('equipmentId') equipmentId: string
  ): Promise<ScenarioEquipmentResponseDto> {
    try {
      logger.info(`删除场景-器材关联: ${scenarioId} - ${equipmentId}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 查找要删除的关联
      const existing = await this.supabaseApi.get('scenario_equipment', {
        scenario_id: scenarioId,
        equipment_id: equipmentId,
      }, { limit: 1 });

      if (!existing || existing.length === 0) {
        throw new NotFoundException(`Association between scenario ${scenarioId} and equipment ${equipmentId} not found`);
      }

      // 删除关联
      await this.supabaseApi.delete('scenario_equipment', existing[0].id);

      logger.info(`场景-器材关联删除成功: ${scenarioId} - ${equipmentId}`);
      return this.mapToResponseDto(existing[0]);
    } catch (error) {
      this.handleError(error, 'remove', { scenarioId, equipmentId });
    }
  }

  /**
   * 获取场景的所有器材
   */
  @Get('scenario/:scenarioId/equipment')
  @ApiOperation({
    summary: '获取场景的所有器材',
    description: '根据场景ID获取该场景可用的所有器材',
  })
  @ApiParam({ name: 'scenarioId', description: '场景ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: [EquipmentWithAssociationDto],
  })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: '场景不存在' })
  async getEquipmentByScenario(
    @Param('scenarioId') scenarioId: string,
    @Query('onlyCommon') onlyCommon: boolean = false
  ): Promise<EquipmentWithAssociationDto[]> {
    try {
      logger.info(`获取场景器材: scenarioId=${scenarioId}, onlyCommon=${onlyCommon}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 验证场景是否存在
      const scenario = await this.supabaseApi.getById('scenarios', scenarioId);
      if (!scenario) {
        throw new NotFoundException(`Scenario with ID ${scenarioId} not found`);
      }

      // 构建查询条件
      const filters: Record<string, any> = {
        scenario_id: scenarioId,
      };

      if (onlyCommon) {
        filters.is_common = true;
      }

      // 获取关联关系
      const associations = await this.supabaseApi.get('scenario_equipment', filters, {
        orderBy: 'created_at.asc',
      });

      // 获取关联的器材详情
      const result: EquipmentWithAssociationDto[] = [];

      for (const assoc of associations) {
        const equipment = await this.supabaseApi.getById('equipment', assoc.equipment_id);
        if (equipment) {
          result.push({
            id: equipment.id,
            code: equipment.code,
            name: equipment.name,
            description: equipment.description || undefined,
            imageUrl: equipment.image_url || undefined,
            isCommon: assoc.is_common,
            isActive: equipment.is_active,
            createdAt: equipment.created_at ? new Date(equipment.created_at) : new Date(),
            updatedAt: equipment.updated_at ? new Date(equipment.updated_at) : new Date(),
          });
        }
      }

      logger.info(`获取场景器材成功: ${scenarioId}, 数量: ${result.length}`);
      return result;
    } catch (error) {
      this.handleError(error, 'getEquipmentByScenario', { scenarioId, onlyCommon });
    }
  }

  /**
   * 获取器材所在的场景
   */
  @Get('equipment/:equipmentId/scenarios')
  @ApiOperation({
    summary: '获取器材所在的场景',
    description: '根据器材ID获取该器材可用的所有场景',
  })
  @ApiParam({ name: 'equipmentId', description: '器材ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: [ScenarioWithAssociationDto],
  })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: '器材不存在' })
  async getScenariosByEquipment(
    @Param('equipmentId') equipmentId: string
  ): Promise<ScenarioWithAssociationDto[]> {
    try {
      logger.info(`获取器材场景: equipmentId=${equipmentId}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 验证器材是否存在
      const equipment = await this.supabaseApi.getById('equipment', equipmentId);
      if (!equipment) {
        throw new NotFoundException(`Equipment with ID ${equipmentId} not found`);
      }

      // 获取关联关系
      const associations = await this.supabaseApi.get('scenario_equipment', {
        equipment_id: equipmentId,
      }, {
        orderBy: 'created_at.asc',
      });

      // 获取关联的场景详情
      const result: ScenarioWithAssociationDto[] = [];

      for (const assoc of associations) {
        const scenario = await this.supabaseApi.getById('scenarios', assoc.scenario_id);
        if (scenario) {
          result.push({
            id: scenario.id,
            code: scenario.code,
            name: scenario.name,
            description: scenario.description || undefined,
            isCommon: assoc.is_common,
            isActive: scenario.is_active,
            createdAt: scenario.created_at ? new Date(scenario.created_at) : new Date(),
            updatedAt: scenario.updated_at ? new Date(scenario.updated_at) : new Date(),
          });
        }
      }

      logger.info(`获取器材场景成功: ${equipmentId}, 数量: ${result.length}`);
      return result;
    } catch (error) {
      this.handleError(error, 'getScenariosByEquipment', { equipmentId });
    }
  }

  /**
   * 检查关联是否存在
   */
  @Get(':scenarioId/:equipmentId/exists')
  @ApiOperation({
    summary: '检查关联是否存在',
    description: '检查指定的场景-器材关联关系是否存在',
  })
  @ApiParam({ name: 'scenarioId', description: '场景ID' })
  @ApiParam({ name: 'equipmentId', description: '器材ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '检查完成',
    schema: {
      type: 'object',
      properties: {
        exists: {
          type: 'boolean',
          description: '是否存在关联',
        },
      },
    },
  })
  async checkExists(
    @Param('scenarioId') scenarioId: string,
    @Param('equipmentId') equipmentId: string
  ): Promise<{ exists: boolean }> {
    try {
      logger.info(`检查场景-器材关联: ${scenarioId} - ${equipmentId}`);
      logger.info('Using direct Supabase API due to database connection issue');

      const exists = await this.checkAssociationExists(scenarioId, equipmentId);

      logger.info(`检查场景-器材关联: ${scenarioId} - ${equipmentId}, 存在: ${exists}`);
      return { exists };
    } catch (error) {
      this.handleError(error, 'checkExists', { scenarioId, equipmentId });
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`ScenarioEquipment Controller ${method} 失败:`, error.stack || error.message, {
      context,
      error: error.message,
    });

    if (error instanceof ResponseError) {
      switch (error.code) {
        case ErrorCodes.SCENARIO_EQUIPMENT.NOT_FOUND.code:
          throw new NotFoundException(error.message);

        case ErrorCodes.SCENARIO_EQUIPMENT.ALREADY_EXISTS.code:
          throw new ConflictException(error.message);

        case ErrorCodes.SCENARIO_EQUIPMENT.INVALID_CODE.code:
        case ErrorCodes.COMMON.VALIDATION_ERROR.code:
          throw new BadRequestException(error.message);

        case ErrorCodes.SCENARIO_EQUIPMENT.CREATE_FAILED.code:
        case ErrorCodes.SCENARIO_EQUIPMENT.UPDATE_FAILED.code:
        case ErrorCodes.SCENARIO_EQUIPMENT.DELETE_FAILED.code:
        case ErrorCodes.SCENARIO_EQUIPMENT.FETCH_FAILED.code:
        default:
          logger.error(
            `未处理的场景器材错误: code=${error.code}, message=${error.message}`,
            error.stack,
          );
          throw new InternalServerErrorException('服务器内部错误');
      }
    }

    // 处理 NestJS 内置异常
    if (error instanceof BadRequestException ||
        error instanceof ConflictException ||
        error instanceof NotFoundException) {
      throw error;
    }

    // 处理其他类型的错误
    if (error.name === 'ValidationError' || error.message?.includes('validation')) {
      throw new BadRequestException('请求参数验证失败');
    }

    throw new InternalServerErrorException('服务器内部错误');
  }
}
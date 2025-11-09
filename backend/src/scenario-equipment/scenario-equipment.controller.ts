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
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';
import { ScenarioEquipmentService } from './scenario-equipment.service';
import { ResponseError } from '../exception/response-error';
import {
  CreateScenarioEquipmentDto,
  UpdateScenarioEquipmentDto,
  BatchCreateScenarioEquipmentDto,
  ScenarioEquipmentResponseDto,
  EquipmentWithAssociationDto,
  ScenarioWithAssociationDto,
} from './dto';

/**
 * ScenarioEquipment Controller 类
 * 提供场景-器材关联关系的REST API接口
 */
@ApiTags('ScenarioEquipment')
@Controller('rest/v1/scenario-equipment')
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class ScenarioEquipmentController {
  private readonly logger = new Logger(ScenarioEquipmentController.name);

  constructor(private readonly scenarioEquipmentService: ScenarioEquipmentService) {
    this.logger.log('ScenarioEquipmentController initialized');
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
      const result = await this.scenarioEquipmentService.createAssociation(createDto);
      this.logger.log(`场景-器材关联创建成功: ${createDto.scenarioId} - ${createDto.equipmentId}`);
      return result;
    } catch (error) {
      this.handleError(error, '创建场景-器材关联失败');
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
  async createBatch(@Body() batchCreateDto: BatchCreateScenarioEquipmentDto): Promise<any> {
    try {
      const result = await this.scenarioEquipmentService.createBatchAssociations(batchCreateDto);
      this.logger.log(`批量创建场景-器材关联成功: ${batchCreateDto.scenarioId}, 数量: ${batchCreateDto.equipmentIds.length}`);
      return result;
    } catch (error) {
      this.handleError(error, '批量创建场景-器材关联失败');
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
      const result = await this.scenarioEquipmentService.updateAssociation(scenarioId, equipmentId, updateDto);
      this.logger.log(`场景-器材关联更新成功: ${scenarioId} - ${equipmentId}`);
      return result;
    } catch (error) {
      this.handleError(error, '更新场景-器材关联失败');
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
      const result = await this.scenarioEquipmentService.deleteAssociation(scenarioId, equipmentId);
      this.logger.log(`场景-器材关联删除成功: ${scenarioId} - ${equipmentId}`);
      return result;
    } catch (error) {
      this.handleError(error, '删除场景-器材关联失败');
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
      const result = await this.scenarioEquipmentService.getEquipmentByScenario(scenarioId, onlyCommon);
      this.logger.log(`获取场景器材成功: ${scenarioId}, 数量: ${result.length}`);
      return result;
    } catch (error) {
      this.handleError(error, '获取场景器材失败');
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
      const result = await this.scenarioEquipmentService.getScenariosByEquipment(equipmentId);
      this.logger.log(`获取器材场景成功: ${equipmentId}, 数量: ${result.length}`);
      return result;
    } catch (error) {
      this.handleError(error, '获取器材场景失败');
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
      const exists = await this.scenarioEquipmentService.checkAssociationExists(scenarioId, equipmentId);
      this.logger.log(`检查场景-器材关联: ${scenarioId} - ${equipmentId}, 存在: ${exists}`);
      return { exists };
    } catch (error) {
      this.handleError(error, '检查场景-器材关联失败');
    }
  }

  /**
   * 统一错误处理
   * @param error 错误对象
   * @param message 错误消息
   */
  private handleError(error: any, message: string): never {
    this.logger.error(message, error.stack);

    if (error instanceof ResponseError) {
      const httpStatus = error.httpStatus;

      if (httpStatus === HttpStatus.BAD_REQUEST) {
        throw new BadRequestException(error.message);
      } else if (httpStatus === HttpStatus.CONFLICT) {
        throw new ConflictException(error.message);
      } else if (httpStatus === HttpStatus.INTERNAL_SERVER_ERROR) {
        throw new InternalServerErrorException(error.message);
      }
    }

    // 默认抛出内部服务器错误
    throw new InternalServerErrorException(message);
  }
}
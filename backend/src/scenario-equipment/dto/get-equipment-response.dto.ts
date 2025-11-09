import { ApiProperty } from '@nestjs/swagger';

/**
 * 场景-器材关联响应 DTO
 */
export class ScenarioEquipmentResponseDto {
  @ApiProperty({
    description: '场景ID',
    example: 'cm3y5x1w2000xxx',
  })
  scenarioId: string;

  @ApiProperty({
    description: '器材ID',
    example: 'cm3y5x1w2000yyy',
  })
  equipmentId: string;

  @ApiProperty({
    description: '是否是常见器材',
    example: true,
  })
  isCommon: boolean;

  @ApiProperty({
    description: '创建时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  createdAt: Date;

  @ApiProperty({
    description: '场景信息',
    type: 'object',
    required: false,
  })
  scenario?: any;

  @ApiProperty({
    description: '器材信息',
    type: 'object',
    required: false,
  })
  equipment?: any;
}

/**
 * 兼容性别名：ScenarioEquipmentDto
 * 为了向后兼容 NestJS Swagger 自动生成的 metadata
 */
export class ScenarioEquipmentDto {
  @ApiProperty({
    description: 'ID（复合）',
    example: 'scenarioId_equipmentId',
  })
  id: string;

  @ApiProperty({
    description: '场景ID',
    example: 'cm3y5x1w2000xxx',
  })
  scenarioId: string;

  @ApiProperty({
    description: '器材ID',
    example: 'cm3y5x1w2000yyy',
  })
  equipmentId: string;

  @ApiProperty({
    description: '是否是常见器材',
    example: true,
  })
  isCommon: boolean;

  @ApiProperty({
    description: '是否活跃',
    example: true,
  })
  isActive: boolean;

  @ApiProperty({
    description: '创建时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  createdAt: string;

  @ApiProperty({
    description: '更新时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  updatedAt: string;
}

/**
 * 分页信息 DTO
 */
export class PaginationDto {
  @ApiProperty({
    description: '总记录数',
    example: 50,
  })
  total: number;

  @ApiProperty({
    description: '当前页码',
    example: 1,
  })
  page: number;

  @ApiProperty({
    description: '每页大小',
    example: 10,
  })
  pageSize: number;

  @ApiProperty({
    description: '总页数',
    example: 5,
  })
  totalPages: number;

  @ApiProperty({
    description: '是否有下一页',
    example: true,
  })
  hasNextPage: boolean;

  @ApiProperty({
    description: '是否有上一页',
    example: false,
  })
  hasPreviousPage: boolean;
}

/**
 * 获取场景器材列表响应 DTO
 */
export class GetScenarioEquipmentResponseDto {
  @ApiProperty({
    description: '场景器材关联列表',
    type: [ScenarioEquipmentDto],
  })
  data: ScenarioEquipmentDto[];

  @ApiProperty({
    description: '分页信息',
    type: PaginationDto,
  })
  pagination: PaginationDto;
}

/**
 * 器材分类统计 DTO
 */
export class ScenarioEquipmentCategoryStatsDto {
  @ApiProperty({
    description: '分类名称',
    example: 'STRENGTH',
  })
  category: string;

  @ApiProperty({
    description: '器材数量',
    example: 15,
  })
  count: number;

  @ApiProperty({
    description: '器材列表',
    type: [Object],
    example: [
      { id: 'cm3y5x1w2000xxx', code: 'DUMBBELLS_5KG', name: '5kg哑铃' },
    ],
  })
  items: Array<{ id: string; code: string; name: string }>;
}

/**
 * 器材统计信息响应 DTO
 */
export class GetScenarioEquipmentStatsResponseDto {
  @ApiProperty({
    description: '总器材数',
    example: 50,
  })
  total: number;

  @ApiProperty({
    description: '活跃器材数',
    example: 45,
  })
  active: number;

  @ApiProperty({
    description: '非活跃器材数',
    example: 5,
  })
  inactive: number;

  @ApiProperty({
    description: '按分类统计',
    type: [ScenarioEquipmentCategoryStatsDto],
  })
  categories: ScenarioEquipmentCategoryStatsDto[];
}

/**
 * 按分类分组的器材响应 DTO
 */
export class GetScenarioEquipmentByCategoryResponseDto {
  @ApiProperty({
    description: '按分类分组的器材',
    example: {
      STRENGTH: [
        { id: 'cm3y5x1w2000xxx', code: 'DUMBBELLS_5KG', name: '5kg哑铃' },
      ],
      CARDIO: [
        { id: 'cm3y5x1w2000yyy', code: 'TREADMILL', name: '跑步机' },
      ],
    },
  })
  data: Record<string, ScenarioEquipmentDto[]>;
}

/**
 * 场景器材列表响应 DTO
 */
export class ScenarioEquipmentListResponseDto {
  @ApiProperty({
    description: '场景-器材关联列表',
    type: [ScenarioEquipmentResponseDto],
  })
  associations: ScenarioEquipmentResponseDto[];

  @ApiProperty({
    description: '总数',
    example: 10,
  })
  total: number;
}

/**
 * 器材信息响应 DTO (带关联信息)
 */
export class EquipmentWithAssociationDto {
  @ApiProperty({
    description: '器材ID',
    example: 'cm3y5x1w2000yyy',
  })
  id: string;

  @ApiProperty({
    description: '器材代码',
    example: 'DUMBBELLS_5KG',
  })
  code: string;

  @ApiProperty({
    description: '器材名称',
    example: '5kg哑铃',
  })
  name: string;

  @ApiProperty({
    description: '器材描述',
    example: '适合初学者使用的5公斤哑铃',
    required: false,
  })
  description?: string;

  @ApiProperty({
    description: '器材图片URL',
    example: 'https://example.com/images/dumbbells-5kg.jpg',
    required: false,
  })
  imageUrl?: string;

  @ApiProperty({
    description: '是否是该场景的常见器材',
    example: true,
  })
  isCommon: boolean;

  @ApiProperty({
    description: '是否活跃',
    example: true,
  })
  isActive: boolean;

  @ApiProperty({
    description: '创建时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  createdAt: Date;

  @ApiProperty({
    description: '更新时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  updatedAt: Date;
}

/**
 * 场景信息响应 DTO (带关联信息)
 */
export class ScenarioWithAssociationDto {
  @ApiProperty({
    description: '场景ID',
    example: 'cm3y5x1w2000xxx',
  })
  id: string;

  @ApiProperty({
    description: '场景代码',
    example: 'OFFICE',
  })
  code: string;

  @ApiProperty({
    description: '场景名称',
    example: '办公室',
  })
  name: string;

  @ApiProperty({
    description: '场景描述',
    example: '适合在办公室进行的训练',
    required: false,
  })
  description?: string;

  @ApiProperty({
    description: '是否是该器材的常见场景',
    example: true,
  })
  isCommon: boolean;

  @ApiProperty({
    description: '是否活跃',
    example: true,
  })
  isActive: boolean;

  @ApiProperty({
    description: '创建时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  createdAt: Date;

  @ApiProperty({
    description: '更新时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  updatedAt: Date;
}
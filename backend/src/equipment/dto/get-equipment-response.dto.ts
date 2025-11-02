import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * 器材基本信息 DTO
 */
export class EquipmentDto {
  @ApiProperty({
    description: '器材ID',
    example: 'cm3y5x1w2000xxx',
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

  @ApiPropertyOptional({
    description: '器材描述',
    example: '适合初学者使用的5公斤哑铃',
  })
  description?: string;

  @ApiPropertyOptional({
    description: '器材分类',
    example: 'STRENGTH',
    enum: ['CARDIO', 'STRENGTH', 'FLEXIBILITY', 'BALANCE', 'OTHER'],
  })
  category?: string;

  @ApiPropertyOptional({
    description: '器材图片URL',
    example: 'https://example.com/images/dumbbells-5kg.jpg',
  })
  imageUrl?: string;

  @ApiPropertyOptional({
    description: '显示顺序',
    example: 1,
  })
  displayOrder?: number;

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
 * 获取器材列表响应 DTO
 */
export class GetEquipmentResponseDto {
  @ApiProperty({
    description: '器材列表',
    type: [EquipmentDto],
  })
  data: EquipmentDto[];

  @ApiProperty({
    description: '分页信息',
    type: PaginationDto,
  })
  pagination: PaginationDto;
}

/**
 * 器材分类统计 DTO
 */
export class EquipmentCategoryStatsDto {
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
export class GetEquipmentStatsResponseDto {
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
    type: [EquipmentCategoryStatsDto],
  })
  categories: EquipmentCategoryStatsDto[];
}

/**
 * 按分类分组的器材响应 DTO
 */
export class GetEquipmentByCategoryResponseDto {
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
  data: Record<string, EquipmentDto[]>;
}
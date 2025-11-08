import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsInt, Min, Max, IsEnum } from 'class-validator';
import { Type, Transform } from 'class-transformer';

/**
 * 器材分类枚举 - 与 Prisma schema 保持一致
 */
export enum EquipmentCategory {
  NONE = 'NONE',
  FURNITURE = 'FURNITURE',
  WALL = 'WALL',
  BOTTLE = 'BOTTLE',
  BAG = 'BAG',
  STAIRS = 'STAIRS',
  FABRIC = 'FABRIC',
  STICK = 'STICK',
  OUTDOOR = 'OUTDOOR',
  CREATIVE = 'CREATIVE',
}

/**
 * 获取器材列表查询参数 DTO
 */
export class GetEquipmentQueryDto {
  /**
   * 页码 (从1开始)
   */
  @ApiPropertyOptional({
    description: '页码 (从1开始)',
    example: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'page必须是整数' })
  @Min(1, { message: 'page必须大于0' })
  page?: number = 1;

  /**
   * 每页大小
   */
  @ApiPropertyOptional({
    description: '每页大小',
    example: 10,
    default: 10,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'pageSize必须是整数' })
  @Min(1, { message: 'pageSize必须大于0' })
  @Max(100, { message: 'pageSize不能超过100' })
  pageSize?: number = 10;

  /**
   * 器材分类筛选
   */
  @ApiPropertyOptional({
    description: '器材分类筛选',
    example: 'FURNITURE',
    enum: EquipmentCategory,
  })
  @IsOptional()
  @IsEnum(EquipmentCategory, { message: 'category必须是有效的器材分类' })
  category?: EquipmentCategory;

  /**
   * 是否包含非活跃器材
   */
  @ApiPropertyOptional({
    description: '是否包含非活跃器材',
    example: false,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  includeInactive?: boolean = false;
}
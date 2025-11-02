import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumberString, Min } from 'class-validator';
import { Transform } from 'class-transformer';

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
  @IsNumberString({}, { message: 'page必须是数字' })
  @Transform(({ value }) => parseInt(value) || 1)
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
  @IsNumberString({}, { message: 'pageSize必须是数字' })
  @Transform(({ value }) => Math.min(parseInt(value) || 10, 100))
  @Min(1, { message: 'pageSize必须大于0' })
  pageSize?: number = 10;

  /**
   * 器材分类筛选
   */
  @ApiPropertyOptional({
    description: '器材分类筛选',
    example: 'CARDIO',
    enum: ['CARDIO', 'STRENGTH', 'FLEXIBILITY', 'BALANCE', 'OTHER'],
  })
  @IsOptional()
  @IsString({ message: 'category必须是字符串' })
  category?: string;

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
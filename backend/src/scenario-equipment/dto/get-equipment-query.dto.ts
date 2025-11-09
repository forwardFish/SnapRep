import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUUID, IsBoolean } from 'class-validator';
import { Transform } from 'class-transformer';

/**
 * 获取场景器材查询参数 DTO
 */
export class GetScenarioEquipmentQueryDto {
  @ApiPropertyOptional({
    description: '场景ID',
    example: 'cm3y5x1w2000xxx',
  })
  @IsOptional()
  @IsUUID('4', { message: 'scenarioId必须是有效的UUID' })
  scenarioId?: string;

  @ApiPropertyOptional({
    description: '器材ID',
    example: 'cm3y5x1w2000yyy',
  })
  @IsOptional()
  @IsUUID('4', { message: 'equipmentId必须是有效的UUID' })
  equipmentId?: string;

  @ApiPropertyOptional({
    description: '是否只返回常见器材',
    example: true,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean({ message: 'onlyCommon必须是布尔值' })
  onlyCommon?: boolean = false;

  @ApiPropertyOptional({
    description: '是否包含场景信息',
    example: true,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean({ message: 'includeScenario必须是布尔值' })
  includeScenario?: boolean = false;

  @ApiPropertyOptional({
    description: '是否包含器材信息',
    example: true,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean({ message: 'includeEquipment必须是布尔值' })
  includeEquipment?: boolean = false;
}
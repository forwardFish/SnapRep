import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  Length,
} from 'class-validator';

/**
 * 创建场景-器材关联 DTO
 */
export class CreateScenarioEquipmentDto {
  @ApiProperty({
    description: '场景ID',
    example: 'cuid_scenario_office',
  })
  @IsString({ message: 'scenarioId必须是字符串' })
  @Length(1, 50, { message: 'scenarioId长度必须在1-50字符之间' })
  scenarioId: string;

  @ApiProperty({
    description: '器材ID',
    example: 'cuid_equipment_chair',
  })
  @IsString({ message: 'equipmentId必须是字符串' })
  @Length(1, 50, { message: 'equipmentId长度必须在1-50字符之间' })
  equipmentId: string;

  @ApiPropertyOptional({
    description: '是否是常见器材',
    example: true,
    default: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'isCommon必须是布尔值' })
  isCommon?: boolean = true;
}

/**
 * 更新场景-器材关联 DTO
 */
export class UpdateScenarioEquipmentDto {
  @ApiProperty({
    description: '是否是常见器材',
    example: true,
  })
  @IsBoolean({ message: 'isCommon必须是布尔值' })
  isCommon: boolean;
}

/**
 * 批量创建场景-器材关联 DTO
 */
export class BatchCreateScenarioEquipmentDto {
  @ApiProperty({
    description: '场景ID',
    example: 'cuid_scenario_office',
  })
  @IsString({ message: 'scenarioId必须是字符串' })
  @Length(1, 50, { message: 'scenarioId长度必须在1-50字符之间' })
  scenarioId: string;

  @ApiProperty({
    description: '器材ID列表',
    example: ['cuid_equipment_chair', 'cuid_equipment_desk'],
    type: [String],
  })
  @IsArray({ message: 'equipmentIds必须是数组' })
  @IsString({ each: true, message: '每个equipmentId必须是字符串' })
  @Length(1, 50, { each: true, message: '每个equipmentId长度必须在1-50字符之间' })
  equipmentIds: string[];

  @ApiPropertyOptional({
    description: '是否是常见器材',
    example: true,
    default: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'isCommon必须是布尔值' })
  isCommon?: boolean = true;
}
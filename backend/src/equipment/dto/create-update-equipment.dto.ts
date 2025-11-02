import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsNumber,
  IsEnum,
  Length,
  Min,
  Max,
  IsUrl,
} from 'class-validator';

/**
 * 器材分类枚举
 */
export enum EquipmentCategory {
  CARDIO = 'CARDIO',
  STRENGTH = 'STRENGTH',
  FLEXIBILITY = 'FLEXIBILITY',
  BALANCE = 'BALANCE',
  OTHER = 'OTHER',
}

/**
 * 创建器材请求 DTO
 */
export class CreateEquipmentDto {
  @ApiProperty({
    description: '器材代码 (唯一)',
    example: 'DUMBBELLS_5KG',
    minLength: 2,
    maxLength: 50,
  })
  @IsString({ message: 'code必须是字符串' })
  @Length(2, 50, { message: 'code长度必须在2-50字符之间' })
  code: string;

  @ApiProperty({
    description: '器材名称',
    example: '5kg哑铃',
    minLength: 1,
    maxLength: 100,
  })
  @IsString({ message: 'name必须是字符串' })
  @Length(1, 100, { message: 'name长度必须在1-100字符之间' })
  name: string;

  @ApiPropertyOptional({
    description: '器材描述',
    example: '适合初学者使用的5公斤哑铃',
    maxLength: 500,
  })
  @IsOptional()
  @IsString({ message: 'description必须是字符串' })
  @Length(0, 500, { message: 'description长度不能超过500字符' })
  description?: string;

  @ApiPropertyOptional({
    description: '器材分类',
    enum: EquipmentCategory,
    example: EquipmentCategory.STRENGTH,
  })
  @IsOptional()
  @IsEnum(EquipmentCategory, { message: 'category必须是有效的器材分类' })
  category?: EquipmentCategory;

  @ApiPropertyOptional({
    description: '器材图片URL',
    example: 'https://example.com/images/dumbbells-5kg.jpg',
  })
  @IsOptional()
  @IsUrl({}, { message: 'imageUrl必须是有效的URL' })
  imageUrl?: string;

  @ApiPropertyOptional({
    description: '显示顺序',
    example: 1,
    minimum: 0,
    maximum: 9999,
  })
  @IsOptional()
  @IsNumber({}, { message: 'displayOrder必须是数字' })
  @Min(0, { message: 'displayOrder不能小于0' })
  @Max(9999, { message: 'displayOrder不能大于9999' })
  displayOrder?: number;

  @ApiPropertyOptional({
    description: '是否活跃',
    example: true,
    default: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'isActive必须是布尔值' })
  isActive?: boolean = true;
}

/**
 * 更新器材请求 DTO
 */
export class UpdateEquipmentDto {
  @ApiPropertyOptional({
    description: '器材代码 (唯一)',
    example: 'DUMBBELLS_5KG',
    minLength: 2,
    maxLength: 50,
  })
  @IsOptional()
  @IsString({ message: 'code必须是字符串' })
  @Length(2, 50, { message: 'code长度必须在2-50字符之间' })
  code?: string;

  @ApiPropertyOptional({
    description: '器材名称',
    example: '5kg哑铃',
    minLength: 1,
    maxLength: 100,
  })
  @IsOptional()
  @IsString({ message: 'name必须是字符串' })
  @Length(1, 100, { message: 'name长度必须在1-100字符之间' })
  name?: string;

  @ApiPropertyOptional({
    description: '器材描述',
    example: '适合初学者使用的5公斤哑铃',
    maxLength: 500,
  })
  @IsOptional()
  @IsString({ message: 'description必须是字符串' })
  @Length(0, 500, { message: 'description长度不能超过500字符' })
  description?: string;

  @ApiPropertyOptional({
    description: '器材分类',
    enum: EquipmentCategory,
    example: EquipmentCategory.STRENGTH,
  })
  @IsOptional()
  @IsEnum(EquipmentCategory, { message: 'category必须是有效的器材分类' })
  category?: EquipmentCategory;

  @ApiPropertyOptional({
    description: '器材图片URL',
    example: 'https://example.com/images/dumbbells-5kg.jpg',
  })
  @IsOptional()
  @IsUrl({}, { message: 'imageUrl必须是有效的URL' })
  imageUrl?: string;

  @ApiPropertyOptional({
    description: '显示顺序',
    example: 1,
    minimum: 0,
    maximum: 9999,
  })
  @IsOptional()
  @IsNumber({}, { message: 'displayOrder必须是数字' })
  @Min(0, { message: 'displayOrder不能小于0' })
  @Max(9999, { message: 'displayOrder不能大于9999' })
  displayOrder?: number;

  @ApiPropertyOptional({
    description: '是否活跃',
    example: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'isActive必须是布尔值' })
  isActive?: boolean;
}

/**
 * 批量更新器材状态请求 DTO
 */
export class BatchUpdateEquipmentStatusDto {
  @ApiProperty({
    description: '器材ID列表',
    example: ['cm3y5x1w2000xxx', 'cm3y5x1w2000yyy'],
    type: [String],
  })
  @IsString({ each: true, message: '每个ID必须是字符串' })
  ids: string[];

  @ApiProperty({
    description: '目标状态',
    example: true,
  })
  @IsBoolean({ message: 'isActive必须是布尔值' })
  isActive: boolean;
}
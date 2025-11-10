import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsDateString, IsArray, IsBoolean } from 'class-validator';

/**
 * 用户分析数据更新 DTO
 */
export class UpdateUserAnalyticsDto {
  @ApiPropertyOptional({
    description: '总锻炼次数',
    example: 100,
  })
  @IsOptional()
  @IsNumber()
  totalWorkouts?: number;

  @ApiPropertyOptional({
    description: '总锻炼时长（秒）',
    example: 36000,
  })
  @IsOptional()
  @IsNumber()
  totalDurationSec?: number;

  @ApiPropertyOptional({
    description: '当前连续锻炼天数',
    example: 7,
  })
  @IsOptional()
  @IsNumber()
  currentStreak?: number;

  @ApiPropertyOptional({
    description: '最长连续锻炼天数',
    example: 30,
  })
  @IsOptional()
  @IsNumber()
  longestStreak?: number;

  @ApiPropertyOptional({
    description: '偏好的锻炼类型',
    example: ['STRENGTH', 'CARDIO'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  preferredIntents?: string[];

  @ApiPropertyOptional({
    description: '偏好的难度',
    example: 'MODERATE',
  })
  @IsOptional()
  @IsString()
  preferredDifficulty?: string;

  @ApiPropertyOptional({
    description: '偏好的锻炼时长（分钟）',
    example: 30,
  })
  @IsOptional()
  @IsNumber()
  preferredDuration?: number;
}

/**
 * 每日指标批量更新 DTO
 */
export class BatchUpdateDailyMetricsDto {
  @ApiProperty({
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  @IsString()
  userId: string;

  @ApiProperty({
    description: '训练日期',
    example: '2024-01-01',
  })
  @IsDateString()
  trainingDate: string;

  @ApiPropertyOptional({
    description: '总会话数',
    example: 5,
  })
  @IsOptional()
  @IsNumber()
  totalSessions?: number;

  @ApiPropertyOptional({
    description: '总时长（秒）',
    example: 1800,
  })
  @IsOptional()
  @IsNumber()
  totalDuration?: number;

  @ApiPropertyOptional({
    description: '总运动数',
    example: 20,
  })
  @IsOptional()
  @IsNumber()
  totalExercises?: number;

  @ApiPropertyOptional({
    description: '完成的会话数',
    example: 4,
  })
  @IsOptional()
  @IsNumber()
  completedSessions?: number;

  @ApiPropertyOptional({
    description: '是否连续锻炼',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isStreakDay?: boolean;
}
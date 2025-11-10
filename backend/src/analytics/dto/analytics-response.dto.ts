import { ApiProperty } from '@nestjs/swagger';

/**
 * 用户指标概览响应 DTO
 */
export class UserMetricsResponseDto {
  @ApiProperty({
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  userId: string;

  @ApiProperty({
    description: '总锻炼次数',
    example: 100,
  })
  totalWorkouts: number;

  @ApiProperty({
    description: '总锻炼时长（秒）',
    example: 36000,
  })
  totalDurationSec: number;

  @ApiProperty({
    description: '当前连续锻炼天数',
    example: 7,
  })
  currentStreak: number;

  @ApiProperty({
    description: '最长连续锻炼天数',
    example: 30,
  })
  longestStreak: number;

  @ApiProperty({
    description: '平均每次锻炼时长（分钟）',
    example: 6,
  })
  avgWorkoutDuration: number;

  @ApiProperty({
    description: '本周锻炼次数',
    example: 5,
  })
  weeklyWorkouts: number;

  @ApiProperty({
    description: '本月锻炼次数',
    example: 20,
  })
  monthlyWorkouts: number;
}

/**
 * 用户漏斗状态响应 DTO
 */
export class UserFunnelResponseDto {
  @ApiProperty({
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  userId: string;

  @ApiProperty({
    description: '注册阶段',
    example: 'COMPLETED',
  })
  registrationStage: string;

  @ApiProperty({
    description: '首次锻炼阶段',
    example: 'COMPLETED',
  })
  firstWorkoutStage: string;

  @ApiProperty({
    description: '留存阶段',
    example: 'ACTIVE',
  })
  retentionStage: string;

  @ApiProperty({
    description: '活跃度评分 (0-100)',
    example: 85,
  })
  engagementScore: number;

  @ApiProperty({
    description: '注册后天数',
    example: 30,
  })
  daysSinceRegistration: number;
}

/**
 * 每日指标响应 DTO
 */
export class DailyMetricsResponseDto {
  @ApiProperty({
    description: '训练日期',
    example: '2024-01-01',
  })
  trainingDate: string;

  @ApiProperty({
    description: '总会话数',
    example: 5,
  })
  totalSessions: number;

  @ApiProperty({
    description: '总时长（秒）',
    example: 1800,
  })
  totalDuration: number;

  @ApiProperty({
    description: '总运动数',
    example: 20,
  })
  totalExercises: number;

  @ApiProperty({
    description: '完成的会话数',
    example: 4,
  })
  completedSessions: number;

  @ApiProperty({
    description: '完成率',
    example: 0.8,
  })
  completionRate: number;

  @ApiProperty({
    description: '是否连续锻炼',
    example: true,
  })
  isStreakDay: boolean;
}

/**
 * 群组分析响应 DTO
 */
export class CohortAnalysisResponseDto {
  @ApiProperty({
    description: '群组标识（注册月份）',
    example: '2024-01',
  })
  cohort: string;

  @ApiProperty({
    description: '群组大小（用户数）',
    example: 100,
  })
  size: number;

  @ApiProperty({
    description: '各周期的留存率',
    example: {
      'day_1': 0.8,
      'day_7': 0.6,
      'day_30': 0.4,
    },
  })
  retention: Record<string, number>;

  @ApiProperty({
    description: '平均生命周期价值',
    example: 85.5,
  })
  averageLTV: number;
}

/**
 * 平台 KPI 指标响应 DTO
 */
export class PlatformKPIResponseDto {
  @ApiProperty({
    description: '总用户数',
    example: 10000,
  })
  totalUsers: number;

  @ApiProperty({
    description: '活跃用户数（过去30天）',
    example: 3000,
  })
  activeUsers: number;

  @ApiProperty({
    description: '新用户数（过去30天）',
    example: 500,
  })
  newUsers: number;

  @ApiProperty({
    description: '总锻炼会话数',
    example: 50000,
  })
  totalSessions: number;

  @ApiProperty({
    description: '平均会话时长（分钟）',
    example: 8.5,
  })
  avgSessionDuration: number;

  @ApiProperty({
    description: '用户留存率',
    example: {
      'day_1': 0.85,
      'day_7': 0.65,
      'day_30': 0.45,
    },
  })
  retentionRates: Record<string, number>;

  @ApiProperty({
    description: '最受欢迎的器材分类',
    example: [
      { category: 'STRENGTH', count: 15000 },
      { category: 'CARDIO', count: 12000 },
    ],
  })
  popularEquipmentCategories: Array<{ category: string; count: number }>;

  @ApiProperty({
    description: '最受欢迎的场景',
    example: [
      { scenario: 'HOME', count: 20000 },
      { scenario: 'OFFICE', count: 18000 },
    ],
  })
  popularScenarios: Array<{ scenario: string; count: number }>;
}
import { IsOptional, IsString, IsBoolean, IsInt, Min, IsEnum, IsDateString, IsNumber, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

// 主题周响应 DTO
export class ThemeWeekResponseDto {
  @ApiProperty({ description: '主题周ID' })
  id: string;

  @ApiProperty({ description: '主题周标题' })
  title: string;

  @ApiProperty({ description: '主题周代码' })
  code: string;

  @ApiProperty({ description: '主题周描述', nullable: true })
  description: string | null;

  @ApiProperty({ description: '器材代码' })
  equipmentCode: string;

  @ApiProperty({ description: '目标练习次数', default: 3 })
  targetExerciseCount: number;

  @ApiProperty({ description: '开始日期' })
  startDate: Date;

  @ApiProperty({ description: '结束日期' })
  endDate: Date;

  @ApiProperty({ description: '状态', enum: ['UPCOMING', 'ACTIVE', 'COMPLETED', 'CANCELLED'] })
  status: string;

  @ApiProperty({ description: '是否可见', default: true })
  isVisible: boolean;

  @ApiProperty({ description: '总参与人数', default: 0 })
  totalParticipants: number;

  @ApiProperty({ description: '总完成人数', default: 0 })
  totalCompletions: number;

  @ApiProperty({ description: '完成率', default: 0.0 })
  completionRate: number;

  @ApiProperty({ description: '奖励类型' })
  rewardType: string;

  @ApiProperty({ description: '奖励数据', nullable: true })
  rewardData: any;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}

// 主题周参与信息 DTO
export class ThemeWeekParticipationDto {
  @ApiProperty({ description: '参与ID' })
  id: string;

  @ApiProperty({ description: '用户ID' })
  userId: string;

  @ApiProperty({ description: '主题周ID' })
  themeWeekId: string;

  @ApiProperty({ description: '参与状态', enum: ['JOINED', 'IN_PROGRESS', 'COMPLETED', 'FAILED'] })
  status: string;

  @ApiProperty({ description: '加入时间' })
  joinedAt: Date;

  @ApiProperty({ description: '完成时间', nullable: true })
  completedAt: Date | null;

  @ApiProperty({ description: '已完成练习数', default: 0 })
  exercisesCompleted: number;

  @ApiProperty({ description: '目标练习数' })
  targetExercises: number;

  @ApiProperty({ description: '进度百分比', default: 0.0 })
  progressPercent: number;

  @ApiProperty({ description: '是否获得奖励', default: false })
  rewardEarned: boolean;

  @ApiProperty({ description: '奖励领取时间', nullable: true })
  rewardClaimedAt: Date | null;

  @ApiProperty({ description: '相关训练会话记录' })
  relatedSessions: string[];
}

// 当前主题周响应 DTO（包含用户参与信息）
export class CurrentThemeWeekDto {
  @ApiProperty({ description: '当前主题周信息', nullable: true })
  current: ThemeWeekResponseDto & {
    participation?: {
      isJoined: boolean;
      progress: {
        completed: number;
        target: number;
        percentage: number;
      };
      timeLeft: string;
    };
    globalStats: {
      totalParticipants: number;
      completionRate: number;
    };
  } | null;

  @ApiProperty({ description: '即将到来的主题周预览' })
  upcoming: Array<{
    title: string;
    equipmentCode: string;
    startDate: string;
  }>;

  @ApiProperty({ description: '消息', nullable: true })
  message?: string;
}

// 加入主题周请求 DTO
export class JoinThemeWeekDto {
  @ApiProperty({ description: '用户ID' })
  @IsString()
  userId: string;
}

// 加入主题周响应 DTO
export class JoinThemeWeekResponseDto {
  @ApiProperty({ description: '是否成功' })
  success: boolean;

  @ApiProperty({ description: '参与信息', nullable: true })
  participation?: ThemeWeekParticipationDto;

  @ApiProperty({ description: '消息' })
  message: string;

  @ApiProperty({ description: '错误信息', nullable: true })
  error?: {
    code: string;
    message: string;
  };
}
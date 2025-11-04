import { IsOptional, IsString, IsArray, IsInt, IsEnum, IsBoolean, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { SessionStatus, IntentType, Difficulty } from '../../common/types/prisma-enums';

// Re-export for Swagger metadata generation
export { SessionStatus, IntentType, Difficulty };

export class CreateWorkoutSessionDto {
  @IsString()
  userId: string;

  @IsEnum(IntentType)
  intentType: IntentType;

  @IsOptional()
  @IsString()
  scenarioId?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetMuscles?: string[];

  @IsInt()
  @Min(30)
  @Max(600)
  @Type(() => Number)
  totalDuration: number;

  @IsEnum(Difficulty)
  difficulty: Difficulty;

  @IsOptional()
  @IsBoolean()
  isSilent?: boolean = false;

  @IsOptional()
  @IsString()
  themeWeekId?: string;

  @IsArray()
  exercises: CreateSessionExerciseDto[];
}

export class CreateSessionExerciseDto {
  @IsString()
  exerciseId: string;

  @IsInt()
  @Min(1)
  @Max(10)
  @Type(() => Number)
  sequenceOrder: number;

  @IsInt()
  @Min(1)
  @Type(() => Number)
  duration: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  sets?: number = 1;
}

export class UpdateWorkoutSessionDto {
  @IsOptional()
  @IsEnum(SessionStatus)
  status?: SessionStatus;

  @IsOptional()
  startedAt?: Date;

  @IsOptional()
  completedAt?: Date;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  actualDuration?: number;

  @IsOptional()
  @IsBoolean()
  followMode?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  currentStep?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  pauseCount?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  skipCount?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  rating?: number;

  @IsOptional()
  @IsString()
  feedback?: string;
}

export class UpdateSessionExerciseDto {
  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  actualDuration?: number;

  @IsOptional()
  startedAt?: Date;

  @IsOptional()
  endedAt?: Date;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  pausedTimes?: number;

  @IsOptional()
  @IsString()
  skipReason?: string;

  @IsOptional()
  @IsEnum(Difficulty)
  difficultyFelt?: Difficulty;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  comfortLevel?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  effectivenessRating?: number;
}

/**
 * 会话查询DTO
 */
export class SessionQueryDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  fromDate?: string;

  @IsOptional()
  @IsString()
  toDate?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number = 20;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  offset?: number = 0;
}

/**
 * 用户统计查询DTO
 */
export class UserStatsQueryDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(365)
  @Type(() => Number)
  days?: number = 30;
}
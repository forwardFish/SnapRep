import { IsOptional, IsString, IsArray, IsInt, Min, Max, IsEnum, ArrayMaxSize } from 'class-validator';
import { Type } from 'class-transformer';
import { IntentType, Difficulty, PrimaryMuscle } from '../../common/types/prisma-enums';

// Re-export for Swagger metadata generation
export { IntentType, Difficulty, PrimaryMuscle };

export class QuickRecommendationDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsEnum(IntentType)
  intent?: IntentType;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  equipment?: string[];

  @IsOptional()
  @IsString()
  scenario?: string;

  @IsOptional()
  @IsArray()
  @IsEnum(PrimaryMuscle, { each: true })
  @ArrayMaxSize(2)
  targetMuscles?: PrimaryMuscle[];

  @IsOptional()
  @IsInt()
  @Min(30)
  @Max(600)
  @Type(() => Number)
  duration?: number = 60;

  @IsOptional()
  @IsEnum(Difficulty)
  difficulty?: Difficulty;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  excludeExerciseIds?: string[];

  @IsOptional()
  @IsString()
  themeWeekId?: string;

  @IsOptional()
  isOffline?: boolean = false;
}

export class ReplaceExerciseDto {
  @IsString()
  sessionId: string;

  @IsInt()
  @Min(1)
  @Max(3)
  @Type(() => Number)
  exercisePosition: number;

  @IsString()
  currentExerciseId: string;

  @IsOptional()
  filters?: {
    intensity?: 'lighter' | 'harder' | 'same';
    equipment?: string[];
    targetMuscle?: PrimaryMuscle;
    excludeIds?: string[];
  };
}

export class AlternativesQueryDto {
  @IsString()
  sessionId: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  equipment?: string[];

  @IsOptional()
  @IsEnum(PrimaryMuscle)
  targetMuscle?: PrimaryMuscle;

  @IsOptional()
  @IsString()
  intensity?: 'lighter' | 'harder' | 'same';

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  @Type(() => Number)
  limit?: number = 10;
}
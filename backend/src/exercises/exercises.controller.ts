import { Controller, Post, Get, Body, Param, Query, HttpCode, HttpStatus, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiParam } from '@nestjs/swagger';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';
import { QuickRecommendationDto, ReplaceExerciseDto, AlternativesQueryDto } from './dto/exercise-recommendation.dto';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';

@ApiTags('Exercise Recommendations')
@Controller('api/v1/recommendations')
export class ExercisesController {
  // private readonly logger = new Logger(ExercisesController.name);

  constructor(
    private readonly workoutRecommendationService: WorkoutRecommendationService,
    private readonly exerciseMatchingService: ExerciseMatchingService,
    private readonly supabaseApi: SupabaseApiService, // 添加SupabaseApiService注入
  ) {}

  @Post('quick')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Quick Workout Recommendation',
    description: '根据用户选择的意图、器材、场景等参数，快速生成3个推荐动作'
  })
  @ApiBody({ type: QuickRecommendationDto })
  @ApiResponse({
    status: 200,
    description: '成功生成推荐',
    schema: {
      type: 'object',
      properties: {
        intent: { type: 'string', example: 'STRETCH' },
        totalDuration: { type: 'number', example: 60 },
        difficulty: { type: 'string', example: 'GREEN' },
        exercises: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              code: { type: 'string' },
              name: { type: 'string' },
              duration: { type: 'number' },
              sets: { type: 'number' },
              difficulty: { type: 'string' },
              primaryMuscle: { type: 'string' },
              keyPoints: { type: 'array', items: { type: 'string' } },
              safetyWarnings: { type: 'array', items: { type: 'string' } },
              demoImageUrl: { type: 'string' },
              tags: { type: 'array', items: { type: 'string' } },
              benefits: { type: 'string' }
            }
          }
        },
        alternatives: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              thumbnailUrl: { type: 'string' },
              difficulty: { type: 'string' },
              benefits: { type: 'string' }
            }
          }
        }
      }
    }
  })
  @ApiResponse({ status: 400, description: '请求参数验证失败' })
  @ApiResponse({ status: 500, description: '服务器内部错误' })
  async quickRecommendation(@Body() dto: QuickRecommendationDto) {
    console.log('🚨 QUICK RECOMMENDATION CALLED:', JSON.stringify(dto));
    logger.info(`快速推荐请求: ${JSON.stringify(dto)}`);

    try {
      console.log('🚨 CALLING WORKOUT RECOMMENDATION SERVICE...');
      const result = await this.workoutRecommendationService.generateQuickRecommendation(dto);

      console.log('🚨 WORKOUT RECOMMENDATION SUCCESS:', result.exercises.length, 'exercises');
      logger.info(`快速推荐成功: 生成${result.exercises.length}个动作`);
      return result;
    } catch (error) {
      console.log('🚨 WORKOUT RECOMMENDATION ERROR:', error.message);
      console.log('🚨 ERROR STACK:', error.stack);
      logger.error(`快速推荐失败: ${error.message}`, error.stack);
      this.handleError(error, 'quickRecommendation', { dto });
    }
  }

  @Post('replace')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Replace Single Exercise',
    description: '替换单个动作，支持强度调整（更温和/更有挑战）'
  })
  @ApiBody({ type: ReplaceExerciseDto })
  @ApiResponse({
    status: 200,
    description: '成功替换动作',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        newExercise: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            difficulty: { type: 'string' },
            benefits: { type: 'string' }
          }
        },
        message: { type: 'string', example: 'Exercise replaced successfully' }
      }
    }
  })
  async replaceExercise(@Body() dto: ReplaceExerciseDto) {
    logger.info(`替换动作请求: sessionId=${dto.sessionId}, position=${dto.exercisePosition}`);

    try {
      const result = await this.exerciseMatchingService.replaceExercise(dto);

      logger.info(`动作替换成功: ${result.newExercise.name}`);
      return result;
    } catch (error) {
      logger.error(`动作替换失败: ${error.message}`, error.stack);
      this.handleError(error, 'replaceExercise', { dto });
    }
  }

  @Get('alternatives')
  @ApiOperation({
    summary: 'Get Alternative Exercises',
    description: '获取替换候选动作列表，用于Bottom Sheet显示'
  })
  @ApiResponse({
    status: 200,
    description: '成功获取候选列表',
    schema: {
      type: 'object',
      properties: {
        alternatives: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              thumbnailUrl: { type: 'string' },
              difficulty: { type: 'string' },
              primaryMuscle: { type: 'string' },
              tags: { type: 'array', items: { type: 'string' } },
              benefits: { type: 'string' }
            }
          }
        },
        filterSummary: {
          type: 'object',
          properties: {
            equipment: { type: 'array', items: { type: 'string' } },
            targetMuscle: { type: 'string' },
            intensity: { type: 'string' }
          }
        }
      }
    }
  })
  async getAlternatives(@Query() query: AlternativesQueryDto) {
    logger.info(`获取替换候选请求: sessionId=${query.sessionId}`);

    try {
      const result = await this.exerciseMatchingService.getAlternatives(query);

      logger.info(`获取候选成功: ${result.alternatives.length}个候选`);
      return result;
    } catch (error) {
      this.handleError(error, 'getAlternatives', { query });
    }
  }

  /**
   * 获取热门推荐动作（通用，不需要用户ID）
   * GET /api/v1/recommendations/popular-exercises
   */
  @Get('popular-exercises')
  @ApiOperation({
    summary: '获取热门推荐动作',
    description: '获取最受欢迎的训练动作列表，适合所有用户'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '热门推荐动作获取成功',
    schema: {
      type: 'object',
      properties: {
        exercises: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string', example: 'exercise-123' },
              code: { type: 'string', example: 'push_ups' },
              name: { type: 'string', example: '俯卧撑' },
              description: { type: 'string' },
              primaryMuscle: { type: 'string', example: 'chest' },
              difficulty: { type: 'string', example: 'INTERMEDIATE' },
              durationSeconds: { type: 'number', example: 60 },
              demoImageUrl: { type: 'string' },
              thumbnailUrl: { type: 'string' },
              popularityScore: { type: 'number', example: 85 }
            }
          }
        }
      }
    }
  })
  async getPopularExercises(@Query('limit') limit: number = 6) {
    logger.info(`获取热门推荐动作: limit=${limit}`);

    try {
      const exercises = await this.getPopularExercisesFromDB(limit);

      return {
        success: true,
        data: { exercises }
      };
    } catch (error) {
      logger.error(`获取热门推荐动作失败: ${error.message}`);
      this.handleError(error, 'getPopularExercises', { limit });
    }
  }

  /**
   * 从数据库获取热门推荐动作
   * @param limit 返回数量限制
   */
  private async getPopularExercisesFromDB(limit: number) {
    try {
      // 查询推荐动作，按创建时间倒序排列（最新的动作优先）
      // 由于数据库中没有trending_score字段，我们使用现有字段
      const popularExercises = await this.supabaseApi.get(
        'exercises',
        {
          is_active: 'eq.true',
        },
        {
          orderBy: 'created_at.desc,name.asc',
          limit: limit,
        }
      );

      if (!popularExercises || popularExercises.length === 0) {
        logger.warn('No popular exercises found, returning empty array');
        return [];
      }

      return popularExercises.map((exercise: any, index: number) => {
        // Parse JSONB description field
        let description = '';
        let keyPoints = [];
        let steps = [];
        let warnings = [];

        if (exercise.description) {
          if (typeof exercise.description === 'object') {
            description = JSON.stringify(exercise.description);
            keyPoints = exercise.description.keyPoints || [];
            steps = exercise.description.steps || [];
            warnings = exercise.description.warnings || [];
          } else {
            description = exercise.description;
          }
        }

        return {
          id: exercise.id,
          code: exercise.code,
          name: exercise.name,
          description: description,
          primaryMuscle: exercise.primary_muscle,
          secondaryMuscles: exercise.secondary_muscles || [],
          intentType: exercise.intent_type,
          difficulty: exercise.difficulty || 'BEGINNER',
          durationSeconds: exercise.default_duration || 60,
          sets: exercise.default_sets || 3,
          durationType: exercise.duration_type,
          demoImageUrl: exercise.demo_image_url,
          demoVideoUrl: exercise.demo_video_url,
          thumbnailUrl: exercise.demo_image_url, // 使用demo_image_url作为缩略图
          tags: exercise.tags || [],
          keyPoints: keyPoints,
          steps: steps,
          safetyWarnings: warnings,
          popularityScore: 100 - (index * 5), // 根据排序给予评分，递减幅度小一点
        };
      });

    } catch (error) {
      logger.error(`查询热门推荐动作失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`Exercises Controller ${method} 失败:`, error.stack || error.message, {
      context,
      error: error.message,
    });

    if (error instanceof ResponseError) {
      throw error; // 直接抛出 ResponseError
    }

    // 处理其他类型的错误
    if (error.name === 'ValidationError' || error.message?.includes('validation')) {
      throw new ResponseError(
        ErrorCodes.COMMON?.VALIDATION_ERROR || { code: 1005, message: 'Validation failed' },
        error,
        context
      );
    }

    throw error;
  }
}
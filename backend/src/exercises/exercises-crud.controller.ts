import { Controller, Get, Post, Body, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';

@ApiTags('Exercises')
@Controller('api/v1/exercises')
export class ExercisesCrudController {
  constructor(
    private readonly supabaseApi: SupabaseApiService,
  ) {}

  /**
   * 搜索训练动作
   * GET /api/v1/exercises/search
   */
  @Get('search')
  @ApiOperation({
    summary: '搜索训练动作',
    description: '根据器材、场景、意图等条件搜索训练动作'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '搜索成功',
  })
  async searchExercises(
    @Query('equipmentCodes') equipmentCodes?: string,
    @Query('scenarioCode') scenarioCode?: string,
    @Query('intent') intent?: string,
    @Query('targetMuscles') targetMuscles?: string,
    @Query('page') page: number = 1,
    @Query('pageSize') pageSize: number = 20,
  ) {
    try {
      const equipmentList = equipmentCodes ? equipmentCodes.split(',') : [];
      const targetMuscleList = targetMuscles ? targetMuscles.split(',') : [];

      logger.info(`搜索训练动作: equipment=${equipmentList}, scenario=${scenarioCode}, page=${page}`);

      // Build query conditions
      const conditions: any = {
        is_active: 'eq.true',
      };

      // Filter by scenario (if provided)
      // Note: This requires a join with exercise_scenarios table or tags

      const exercises = await this.supabaseApi.get(
        'exercises',
        conditions,
        {
          orderBy: 'created_at.desc',
          limit: pageSize,
          offset: (page - 1) * pageSize,
        }
      );

      const formattedExercises = exercises.map((exercise: any) => {
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
          difficulty: exercise.difficulty,
          durationSeconds: exercise.default_duration,
          sets: exercise.default_sets,
          durationType: exercise.duration_type,
          demoImageUrl: exercise.demo_image_url,
          demoVideoUrl: exercise.demo_video_url,
          thumbnailUrl: exercise.demo_image_url,
          tags: exercise.tags || [],
          keyPoints: keyPoints,
          steps: steps,
          safetyWarnings: warnings,
        };
      });

      return {
        success: true,
        data: formattedExercises,
        pagination: {
          page,
          pageSize,
          total: formattedExercises.length,
        }
      };
    } catch (error) {
      logger.error(`搜索训练动作失败: ${error.message}`);
      this.handleError(error, 'searchExercises', { equipmentCodes, scenarioCode });
    }
  }

  /**
   * 检查器材可用性
   * POST /api/v1/exercises/check-availability
   */
  @Post('check-availability')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '检查器材的训练动作可用性',
    description: '检查指定器材是否有可用的训练动作'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '检查成功',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean' },
        count: { type: 'number', example: 5 },
        hasExercises: { type: 'boolean', example: true }
      }
    }
  })
  async checkAvailability(@Body() body: { equipment: string[] }) {
    try {
      logger.info(`检查器材可用性: ${body.equipment?.join(', ')}`);

      if (!body.equipment || body.equipment.length === 0) {
        return {
          success: true,
          count: 0,
          hasExercises: false
        };
      }

      // Query exercises table to count available exercises
      // This is a simple implementation - you may need to join with exercise_equipment table
      const exercises = await this.supabaseApi.get(
        'exercises',
        {
          is_active: 'eq.true',
        },
        {
          limit: 100, // Get a reasonable sample
        }
      );

      // Filter by equipment tags (simple check)
      const matchingExercises = exercises.filter((ex: any) => {
        const tags = ex.tags || [];
        return body.equipment.some(eq =>
          tags.some((tag: string) => tag.toLowerCase().includes(eq.toLowerCase()))
        );
      });

      return {
        success: true,
        count: matchingExercises.length,
        hasExercises: matchingExercises.length > 0
      };
    } catch (error) {
      logger.error(`检查器材可用性失败: ${error.message}`);
      this.handleError(error, 'checkAvailability', { equipment: body.equipment });
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`Exercises CRUD Controller ${method} 失败:`, error.stack || error.message, {
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

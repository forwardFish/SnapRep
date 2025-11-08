import { Controller, Post, Get, Body, Param, Query, HttpCode, HttpStatus, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiParam } from '@nestjs/swagger';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';
import { QuickRecommendationDto, ReplaceExerciseDto, AlternativesQueryDto } from './dto/exercise-recommendation.dto';

@ApiTags('Exercise Recommendations')
@Controller('api/v1/recommendations')
export class ExercisesController {
  private readonly logger = new Logger(ExercisesController.name);

  constructor(
    private readonly workoutRecommendationService: WorkoutRecommendationService,
    private readonly exerciseMatchingService: ExerciseMatchingService,
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
    this.logger.log(`快速推荐请求: ${JSON.stringify(dto)}`);

    try {
      console.log('🚨 CALLING WORKOUT RECOMMENDATION SERVICE...');
      const result = await this.workoutRecommendationService.generateQuickRecommendation(dto);

      console.log('🚨 WORKOUT RECOMMENDATION SUCCESS:', result.exercises.length, 'exercises');
      this.logger.log(`快速推荐成功: 生成${result.exercises.length}个动作`);
      return result;
    } catch (error) {
      console.log('🚨 WORKOUT RECOMMENDATION ERROR:', error.message);
      console.log('🚨 ERROR STACK:', error.stack);
      this.logger.error(`快速推荐失败: ${error.message}`, error.stack);
      throw error;
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
    this.logger.log(`替换动作请求: sessionId=${dto.sessionId}, position=${dto.exercisePosition}`);

    try {
      const result = await this.exerciseMatchingService.replaceExercise(dto);

      this.logger.log(`动作替换成功: ${result.newExercise.name}`);
      return result;
    } catch (error) {
      this.logger.error(`动作替换失败: ${error.message}`, error.stack);
      throw error;
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
    this.logger.log(`获取替换候选请求: sessionId=${query.sessionId}`);

    try {
      const result = await this.exerciseMatchingService.getAlternatives(query);

      this.logger.log(`获取候选成功: ${result.alternatives.length}个候选`);
      return result;
    } catch (error) {
      this.logger.error(`获取候选失败: ${error.message}`, error.stack);
      throw error;
    }
  }
}
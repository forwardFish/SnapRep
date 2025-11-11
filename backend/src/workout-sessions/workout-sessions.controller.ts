import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  HttpStatus,
  Logger,
  ParseUUIDPipe,
  ValidationPipe,
  BadRequestException
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBearerAuth,
  ApiBody
} from '@nestjs/swagger';
import { WorkoutSessionsService } from './workout-sessions.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import {
  CreateWorkoutSessionDto,
  UpdateWorkoutSessionDto,
  UpdateSessionExerciseDto,
  SessionQueryDto,
  UserStatsQueryDto
} from './dto/workout-session.dto';
import { QuickRecommendationDto } from '../exercises/dto/exercise-recommendation.dto';
import { logger } from '../common/logger/logger';

/**
 * WorkoutSessions REST API 控制器
 * 提供训练会话管理的 REST 接口
 */
@ApiTags('Workout Sessions')
@Controller('api/v1')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class WorkoutSessionsController {
  // private readonly logger = new Logger(WorkoutSessionsController.name);

  constructor(private readonly workoutSessionsService: WorkoutSessionsService) {}

  /**
   * 创建新的训练会话
   * POST /api/v1/workout-sessions
   */
  @Post('workout-sessions')
  @ApiOperation({
    summary: '创建训练会话',
    description: '根据用户选择的参数和动作列表创建新的训练会话'
  })
  @ApiBody({ type: CreateWorkoutSessionDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '训练会话创建成功',
    schema: {
      type: 'object',
      properties: {
        id: { type: 'string', example: 'cuid_session_123' },
        userId: { type: 'string', example: 'user-uuid-123' },
        intentType: { type: 'string', example: 'STRETCH' },
        status: { type: 'string', example: 'PENDING' },
        totalDuration: { type: 'number', example: 300 },
        difficulty: { type: 'string', example: 'GREEN' },
        sessionExercises: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              exerciseId: { type: 'string' },
              sequenceOrder: { type: 'number' },
              duration: { type: 'number' },
              sets: { type: 'number' }
            }
          }
        },
        createdAt: { type: 'string', format: 'date-time' }
      }
    }
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误或用户有过多活跃会话'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '指定的动作不存在'
  })
  async createWorkoutSession(
    @Body(ValidationPipe) createDto: CreateWorkoutSessionDto
  ) {
    logger.debug(`创建训练会话请求: userId=${createDto.userId}`);

    try {
      const session = await this.workoutSessionsService.createSession(createDto);

      return {
        success: true,
        data: session,
        message: 'Workout session created successfully'
      };
    } catch (error) {
      logger.error(`创建训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 从推荐结果创建训练会话
   * POST /api/v1/workout-sessions/from-recommendation
   */
  @Post('workout-sessions/from-recommendation')
  @ApiOperation({
    summary: '从推荐结果创建训练会话',
    description: '根据推荐参数生成动作推荐，并创建对应的训练会话'
  })
  @ApiBody({ type: QuickRecommendationDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '基于推荐的训练会话创建成功',
    schema: {
      type: 'object',
      properties: {
        id: { type: 'string' },
        recommendationId: { type: 'string' },
        sessionExercises: { type: 'array', items: { type: 'object' } },
        alternatives: { type: 'array', items: { type: 'object' } }
      }
    }
  })
  async createSessionFromRecommendation(
    @Body(ValidationPipe) recommendationDto: QuickRecommendationDto
  ) {
    logger.debug(`从推荐创建会话: userId=${recommendationDto.userId}`);

    if (!recommendationDto.userId) {
      throw new BadRequestException('userId is required for creating session from recommendation');
    }

    try {
      const session = await this.workoutSessionsService.createSessionFromRecommendation(
        recommendationDto.userId,
        recommendationDto
      );

      return {
        success: true,
        data: session,
        message: 'Session created from recommendation successfully'
      };
    } catch (error) {
      logger.error(`从推荐创建会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取训练会话详情
   * GET /api/v1/workout-sessions/:id
   */
  @Get('workout-sessions/:id')
  @ApiOperation({
    summary: '获取训练会话详情',
    description: '根据会话ID获取完整的训练会话信息，包括动作列表'
  })
  @ApiParam({
    name: 'id',
    description: '训练会话ID',
    example: 'cuid_session_123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '训练会话详情获取成功'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '训练会话不存在'
  })
  async getWorkoutSession(
    @Param('id') id: string,
    @Query('includeExercises') includeExercises: boolean = true
  ) {
    logger.debug(`获取训练会话详情: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.findById(id, includeExercises);

      return {
        success: true,
        data: session
      };
    } catch (error) {
      logger.error(`获取训练会话详情失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新训练会话
   * PATCH /api/v1/workout-sessions/:id
   */
  @Patch('workout-sessions/:id')
  @ApiOperation({
    summary: '更新训练会话',
    description: '更新训练会话的状态、进度等信息'
  })
  @ApiParam({
    name: 'id',
    description: '训练会话ID',
    example: 'cuid_session_123'
  })
  @ApiBody({ type: UpdateWorkoutSessionDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '训练会话更新成功'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '训练会话不存在'
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '状态转换不合法'
  })
  async updateWorkoutSession(
    @Param('id') id: string,
    @Body(ValidationPipe) updateDto: UpdateWorkoutSessionDto
  ) {
    logger.debug(`更新训练会话: sessionId=${id}, status=${updateDto.status}`);

    try {
      const session = await this.workoutSessionsService.updateSession(id, updateDto);

      return {
        success: true,
        data: session,
        message: 'Workout session updated successfully'
      };
    } catch (error) {
      logger.error(`更新训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 完成训练会话
   * POST /api/v1/workout-sessions/:id/complete
   */
  @Post('workout-sessions/:id/complete')
  @ApiOperation({
    summary: '完成训练会话',
    description: '标记训练会话为完成状态，记录实际时长和用户评价'
  })
  @ApiParam({
    name: 'id',
    description: '训练会话ID',
    example: 'cuid_session_123'
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        actualDuration: { type: 'number', description: '实际训练时长（秒）', example: 280 },
        rating: { type: 'number', minimum: 1, maximum: 5, description: '用户评分', example: 4 },
        feedback: { type: 'string', description: '用户反馈', example: '动作很棒，有点累但很有效果' }
      }
    }
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '训练会话完成成功'
  })
  async completeSession(
    @Param('id') id: string,
    @Body() completeData: {
      actualDuration?: number;
      rating?: number;
      feedback?: string;
    }
  ) {
    logger.debug(`完成训练会话: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.completeSession(
        id,
        completeData.actualDuration,
        completeData.rating,
        completeData.feedback
      );

      return {
        success: true,
        data: session,
        message: 'Workout session completed successfully'
      };
    } catch (error) {
      logger.error(`完成训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 放弃训练会话
   * POST /api/v1/workout-sessions/:id/abandon
   */
  @Post('workout-sessions/:id/abandon')
  @ApiOperation({
    summary: '放弃训练会话',
    description: '标记训练会话为放弃状态'
  })
  @ApiParam({
    name: 'id',
    description: '训练会话ID',
    example: 'cuid_session_123'
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        reason: { type: 'string', description: '放弃原因', example: '时间不够了' }
      }
    }
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '训练会话放弃成功'
  })
  async abandonSession(
    @Param('id') id: string,
    @Body() abandonData: { reason?: string }
  ) {
    logger.debug(`放弃训练会话: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.abandonSession(id, abandonData.reason);

      return {
        success: true,
        data: session,
        message: 'Workout session abandoned'
      };
    } catch (error) {
      logger.error(`放弃训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的训练会话列表
   * GET /api/v1/users/:userId/sessions
   */
  @Get('users/:userId/sessions')
  @ApiOperation({
    summary: '获取用户训练会话列表',
    description: '获取指定用户的训练会话历史记录，支持筛选和分页'
  })
  @ApiParam({
    name: 'userId',
    description: '用户ID',
    example: 'user-uuid-123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '用户训练会话列表获取成功'
  })
  async getUserSessions(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query(ValidationPipe) query: SessionQueryDto
  ) {
    logger.debug(`获取用户会话列表: userId=${userId}`);

    try {
      const sessions = await this.workoutSessionsService.findUserSessions(userId, query);

      return {
        success: true,
        data: sessions,
        pagination: {
          limit: query.limit || 20,
          offset: query.offset || 0
        }
      };
    } catch (error) {
      logger.error(`获取用户会话列表失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新会话中的动作
   * PATCH /api/v1/workout-sessions/:sessionId/exercises/:exerciseId
   */
  @Patch('workout-sessions/:sessionId/exercises/:exerciseId')
  @ApiOperation({
    summary: '更新会话中的动作',
    description: '更新训练会话中特定动作的完成状态和用户反馈'
  })
  @ApiParam({ name: 'sessionId', description: '训练会话ID' })
  @ApiParam({ name: 'exerciseId', description: '动作ID' })
  @ApiBody({ type: UpdateSessionExerciseDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '会话动作更新成功'
  })
  async updateSessionExercise(
    @Param('sessionId') sessionId: string,
    @Param('exerciseId') exerciseId: string,
    @Body(ValidationPipe) updateDto: UpdateSessionExerciseDto
  ) {
    logger.debug(`更新会话动作: sessionId=${sessionId}, exerciseId=${exerciseId}`);

    try {
      const updatedExercise = await this.workoutSessionsService.updateSessionExercise(
        sessionId,
        exerciseId,
        updateDto
      );

      return {
        success: true,
        data: updatedExercise,
        message: 'Session exercise updated successfully'
      };
    } catch (error) {
      logger.error(`更新会话动作失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户训练统计
   * GET /api/v1/users/:userId/stats
   */
  @Get('users/:userId/stats')
  @ApiOperation({
    summary: '获取用户训练统计',
    description: '获取用户的训练统计数据，包括总时长、连击天数等'
  })
  @ApiParam({
    name: 'userId',
    description: '用户ID',
    example: 'user-uuid-123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '用户训练统计获取成功',
    schema: {
      type: 'object',
      properties: {
        totalSessions: { type: 'number', example: 25 },
        totalDuration: { type: 'number', example: 7500 },
        averageDuration: { type: 'number', example: 300 },
        currentStreak: { type: 'number', example: 7 },
        todayCompletedGlobal: { type: 'number', example: 156 },
        activeSessionsGlobal: { type: 'number', example: 23 },
        recentSessions: { type: 'array', items: { type: 'object' } }
      }
    }
  })
  async getUserStats(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query(ValidationPipe) query: UserStatsQueryDto
  ) {
    logger.debug(`获取用户训练统计: userId=${userId}, days=${query.days}`);

    try {
      const stats = await this.workoutSessionsService.getUserStats(userId, query);

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      logger.error(`获取用户训练统计失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 健康检查
   * GET /api/v1/workout-sessions/health
   */
  @Get('workout-sessions/health')
  @ApiOperation({
    summary: '服务健康检查',
    description: '检查训练会话服务的健康状态'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '服务状态正常'
  })
  async healthCheck() {
    try {
      const health = await this.workoutSessionsService.healthCheck();

      return {
        success: true,
        data: health
      };
    } catch (error) {
      logger.error(`健康检查失败: ${error.message}`);
      throw error;
    }
  }
}
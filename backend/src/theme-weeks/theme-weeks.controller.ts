import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Logger,
  UseGuards,
  Request,
  BadRequestException
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ThemeWeeksService } from './theme-weeks.service';
import {
  CurrentThemeWeekDto,
  JoinThemeWeekDto,
  JoinThemeWeekResponseDto,
} from './dto/theme-week.dto';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';


@ApiTags('Theme Weeks')
@Controller('/api/v1/theme-weeks')
export class ThemeWeeksController {
  // private readonly logger = new Logger(ThemeWeeksController.name);

  constructor(
    private readonly themeWeeksService: ThemeWeeksService,
    private readonly supabaseApi: SupabaseApiService, // Add SupabaseApiService injection
  ) {
    logger.info('ThemeWeeksController initialized');
  }

  /**
   * 使用SupabaseApiService获取当前主题周
   * 替换原来的service调用以避免数据库连接问题
   */
  private async getCurrentThemeWeekDirect(userId?: string): Promise<CurrentThemeWeekDto> {
    try {
      // 获取当前活跃的主题周
      const activeThemeWeeks = await this.supabaseApi.get('theme_weeks', {
        status: 'ACTIVE',
      }, {
        orderBy: 'start_date.desc',
        limit: 1,
      });

      if (!activeThemeWeeks || activeThemeWeeks.length === 0) {
        // 返回没有活跃主题周的响应
        return {
          current: null,
          upcoming: [],
          message: 'No active theme week found',
        };
      }

      const currentThemeWeek = activeThemeWeeks[0];

      // 获取即将到来的主题周
      const upcomingThemeWeeks = await this.supabaseApi.get('theme_weeks', {
        status: 'UPCOMING',
      }, {
        orderBy: 'start_date.asc',
        limit: 3,
      });

      // 构建当前主题周响应
      let current: any = {
        id: currentThemeWeek.id,
        title: currentThemeWeek.title,
        code: currentThemeWeek.code,
        description: currentThemeWeek.description,
        equipmentCode: currentThemeWeek.equipment_code,
        targetExerciseCount: currentThemeWeek.target_exercise_count || 3,
        startDate: new Date(currentThemeWeek.start_date),
        endDate: new Date(currentThemeWeek.end_date),
        status: currentThemeWeek.status,
        isVisible: currentThemeWeek.is_visible !== false,
        totalParticipants: currentThemeWeek.total_participants || 0,
        totalCompletions: currentThemeWeek.total_completions || 0,
        completionRate: currentThemeWeek.completion_rate || 0.0,
        rewardType: currentThemeWeek.reward_type,
        rewardData: currentThemeWeek.reward_data,
        createdAt: new Date(currentThemeWeek.created_at),
        updatedAt: new Date(currentThemeWeek.updated_at),
        globalStats: {
          totalParticipants: currentThemeWeek.total_participants || 0,
          completionRate: currentThemeWeek.completion_rate || 0.0,
        },
      };

      // 如果提供了用户ID，获取用户参与状态
      if (userId) {
        try {
          const userParticipations = await this.supabaseApi.get('theme_week_participations', {
            user_id: userId,
            theme_week_id: currentThemeWeek.id,
          }, { limit: 1 });

          if (userParticipations && userParticipations.length > 0) {
            const participation = userParticipations[0];
            const completed = participation.exercises_completed || 0;
            const target = participation.target_exercises || currentThemeWeek.target_exercise_count || 3;
            const percentage = target > 0 ? (completed / target) * 100 : 0;

            // 计算剩余时间
            const endDate = new Date(currentThemeWeek.end_date);
            const now = new Date();
            const timeLeftMs = endDate.getTime() - now.getTime();
            const daysLeft = Math.max(0, Math.ceil(timeLeftMs / (1000 * 60 * 60 * 24)));

            current.participation = {
              isJoined: true,
              progress: {
                completed,
                target,
                percentage: Math.round(percentage),
              },
              timeLeft: `${daysLeft} days left`,
            };
          } else {
            const endDate = new Date(currentThemeWeek.end_date);
            const now = new Date();
            const timeLeftMs = endDate.getTime() - now.getTime();
            const daysLeft = Math.max(0, Math.ceil(timeLeftMs / (1000 * 60 * 60 * 24)));

            current.participation = {
              isJoined: false,
              progress: {
                completed: 0,
                target: currentThemeWeek.target_exercise_count || 3,
                percentage: 0,
              },
              timeLeft: `${daysLeft} days left`,
            };
          }
        } catch (error) {
          logger.warn(`Failed to get user participation for ${userId}: ${error.message}`);
          current.participation = {
            isJoined: false,
            progress: {
              completed: 0,
              target: currentThemeWeek.target_exercise_count || 3,
              percentage: 0,
            },
            timeLeft: 'Unknown',
          };
        }
      }

      const result: CurrentThemeWeekDto = {
        current,
        upcoming: upcomingThemeWeeks.map(week => ({
          title: week.title,
          equipmentCode: week.equipment_code,
          startDate: new Date(week.start_date).toISOString(),
        })),
      };

      return result;
    } catch (error) {
      logger.error('Failed to get current theme week via direct API:', error);
      throw error;
    }
  }

  @Get('current')
  @ApiOperation({
    summary: '获取当前主题周',
    description: '获取当前活跃的主题周信息，包含用户参与状态（如果提供了用户ID）'
  })
  @ApiQuery({
    name: 'userId',
    required: false,
    description: '用户ID，用于获取用户参与状态'
  })
  @ApiResponse({
    status: 200,
    description: '成功获取当前主题周信息',
    type: CurrentThemeWeekDto
  })
  async getCurrentThemeWeek(
    @Query('userId') userId?: string,
  ): Promise<CurrentThemeWeekDto> {
    try {
      logger.debug(`Getting current theme week${userId ? ` for user ${userId}` : ''}`);
      logger.info('Using direct Supabase API due to database connection issue');

      const result = await this.getCurrentThemeWeekDirect(userId);

      logger.debug('Current theme week retrieved successfully via direct API');
      return result;
    } catch (error) {
      this.handleError(error, 'getCurrentThemeWeek', { userId });
    }
  }

  /**
   * 统一错误处理方法
   * @param error 错误对象
   * @param method 方法名
   * @param context 上下文信息
   */
  private handleError(error: any, method: string, context?: any): never {
    logger.error(`${method} failed`, {
      error: error.message,
      context,
      stack: error.stack,
    });

    if (error instanceof ResponseError) {
      throw error; // 直接抛出 ResponseError
    }

    // 未知错误
    throw new BadRequestException('Theme week service error, please try again later');
  }

  @Post(':themeWeekId/join')
  @ApiOperation({
    summary: '加入主题周挑战',
    description: '用户加入指定的主题周挑战'
  })
  @ApiResponse({
    status: 200,
    description: '成功加入主题周',
    type: JoinThemeWeekResponseDto
  })
  @ApiResponse({
    status: 400,
    description: '请求参数错误'
  })
  @ApiResponse({
    status: 404,
    description: '主题周不存在'
  })
  @ApiResponse({
    status: 409,
    description: '用户已加入该主题周'
  })
  async joinThemeWeek(
    @Param('themeWeekId') themeWeekId: string,
    @Body() joinDto: JoinThemeWeekDto,
  ): Promise<JoinThemeWeekResponseDto> {
    try {
      logger.debug(`User ${joinDto.userId} attempting to join theme week ${themeWeekId}`);
      logger.info('Using direct Supabase API due to database connection issue');

      if (!joinDto.userId) {
        throw new BadRequestException('User ID is required');
      }

      // 检查主题周是否存在且活跃
      const themeWeek = await this.supabaseApi.getById('theme_weeks', themeWeekId);
      if (!themeWeek) {
        return {
          success: false,
          message: 'Theme week not found',
          error: {
            code: 'THEME_WEEK_NOT_FOUND',
            message: 'The specified theme week does not exist',
          },
        };
      }

      if (themeWeek.status !== 'ACTIVE') {
        return {
          success: false,
          message: 'Theme week is not active',
          error: {
            code: 'THEME_WEEK_INACTIVE',
            message: 'This theme week is not currently active',
          },
        };
      }

      // 检查用户是否已经参与
      const existingParticipation = await this.supabaseApi.get('theme_week_participations', {
        user_id: joinDto.userId,
        theme_week_id: themeWeekId,
      }, { limit: 1 });

      if (existingParticipation && existingParticipation.length > 0) {
        return {
          success: false,
          message: 'User already joined this theme week',
          error: {
            code: 'ALREADY_JOINED',
            message: 'You have already joined this theme week',
          },
        };
      }

      // 创建参与记录
      const participationId = `thm_ptcp_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
      const participation = await this.supabaseApi.post('theme_week_participations', {
        id: participationId,
        user_id: joinDto.userId,
        theme_week_id: themeWeekId,
        status: 'JOINED',
        joined_at: new Date().toISOString(),
        exercises_completed: 0,
        target_exercises: themeWeek.target_exercise_count || 3,
        progress_percent: 0.0,
        reward_earned: false,
        related_sessions: [],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

      logger.info(`User ${joinDto.userId} successfully joined theme week ${themeWeekId}`);

      return {
        success: true,
        message: 'Successfully joined theme week',
        participation: {
          id: participation.id,
          userId: participation.user_id,
          themeWeekId: participation.theme_week_id,
          status: participation.status,
          joinedAt: new Date(participation.joined_at),
          completedAt: participation.completed_at ? new Date(participation.completed_at) : null,
          exercisesCompleted: participation.exercises_completed,
          targetExercises: participation.target_exercises,
          progressPercent: participation.progress_percent,
          rewardEarned: participation.reward_earned,
          rewardClaimedAt: participation.reward_claimed_at ? new Date(participation.reward_claimed_at) : null,
          relatedSessions: participation.related_sessions || [],
        },
      };
    } catch (error) {
      logger.error(`Failed to join theme week ${themeWeekId}`, error);
      this.handleError(error, 'joinThemeWeek', { themeWeekId, userId: joinDto.userId });
    }
  }

  @Post(':themeWeekId/update-progress')
  @ApiOperation({
    summary: '更新用户主题周进度',
    description: '当用户完成相关练习时，更新其在主题周中的进度'
  })
  @ApiResponse({
    status: 200,
    description: '成功更新进度'
  })
  @ApiResponse({
    status: 404,
    description: '用户未参与该主题周'
  })
  async updateProgress(
    @Param('themeWeekId') themeWeekId: string,
    @Body() updateDto: { userId: string; exercisesCompleted: number },
  ) {
    try {
      logger.debug(`Updating progress for user ${updateDto.userId} in theme week ${themeWeekId}`);
      logger.info('Using direct Supabase API due to database connection issue');

      // 查找用户的参与记录
      const participations = await this.supabaseApi.get('theme_week_participations', {
        user_id: updateDto.userId,
        theme_week_id: themeWeekId,
      }, { limit: 1 });

      if (!participations || participations.length === 0) {
        throw new BadRequestException('User has not joined this theme week');
      }

      const participation = participations[0];
      const targetExercises = participation.target_exercises;
      const newProgress = Math.min(updateDto.exercisesCompleted, targetExercises);
      const progressPercent = targetExercises > 0 ? (newProgress / targetExercises) * 100 : 0;
      const isCompleted = newProgress >= targetExercises;

      // 更新参与记录
      const updatedParticipation = await this.supabaseApi.patch('theme_week_participations', participation.id, {
        exercises_completed: newProgress,
        progress_percent: progressPercent,
        status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        completed_at: isCompleted ? new Date().toISOString() : null,
        reward_earned: isCompleted,
        updated_at: new Date().toISOString(),
      });

      logger.info(`Progress updated for user ${updateDto.userId}: ${newProgress}/${targetExercises}`);

      const result = {
        id: updatedParticipation.id,
        userId: updatedParticipation.user_id,
        themeWeekId: updatedParticipation.theme_week_id,
        status: updatedParticipation.status,
        exercisesCompleted: updatedParticipation.exercises_completed,
        targetExercises: updatedParticipation.target_exercises,
        progressPercent: Math.round(updatedParticipation.progress_percent),
        rewardEarned: updatedParticipation.reward_earned,
        completedAt: updatedParticipation.completed_at ? new Date(updatedParticipation.completed_at) : null,
      };

      return {
        success: true,
        data: result,
      };
    } catch (error) {
      logger.error(`Failed to update progress for theme week ${themeWeekId}`, error);
      this.handleError(error, 'updateProgress', { themeWeekId, userId: updateDto.userId });
    }
  }
}
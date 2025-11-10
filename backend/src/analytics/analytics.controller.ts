import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  HttpStatus,
  Logger,
  UseGuards,
  ValidationPipe,
  UsePipes,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { UpdateUserAnalyticsDto, BatchUpdateDailyMetricsDto } from './dto/analytics.dto';
import {
  UserMetricsResponseDto,
  UserFunnelResponseDto,
  DailyMetricsResponseDto,
  CohortAnalysisResponseDto,
  PlatformKPIResponseDto,
} from './dto/analytics-response.dto';

/**
 * Analytics Controller 类
 * 提供用户分析和数据统计相关的 REST API 接口
 */
@ApiTags('Analytics')
@Controller('api/v1/analytics')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class AnalyticsController {
  private readonly logger = new Logger(AnalyticsController.name);

  constructor(private readonly supabaseApi: SupabaseApiService) {
    this.logger.log('AnalyticsController initialized with SupabaseApiService');
  }

  /**
   * 更新用户分析数据
   */
  @Patch('users/:id')
  @ApiOperation({
    summary: '更新用户分析数据',
    description: '更新指定用户的分析统计数据',
  })
  @ApiParam({
    name: 'id',
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiBody({ type: UpdateUserAnalyticsDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '更新成功',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: '用户分析数据更新成功' },
        userId: { type: 'string', example: 'cm3y5x1w2000xxx' },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '用户不存在',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: '未授权访问',
  })
  async updateUserAnalytics(
    @Param('id') userId: string,
    @Body() updateDto: UpdateUserAnalyticsDto,
  ) {
    try {
      this.logger.log(`更新用户分析数据: ${userId}`);

      // 检查用户是否存在
      const user = await this.supabaseApi.getById('users', userId);
      if (!user) {
        throw new Error('用户不存在');
      }

      // 更新用户分析数据
      const updateData: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateDto.totalWorkouts !== undefined) updateData.total_workouts = updateDto.totalWorkouts;
      if (updateDto.totalDurationSec !== undefined) updateData.total_duration_sec = updateDto.totalDurationSec;
      if (updateDto.currentStreak !== undefined) updateData.current_streak = updateDto.currentStreak;
      if (updateDto.longestStreak !== undefined) updateData.longest_streak = updateDto.longestStreak;
      if (updateDto.preferredIntents !== undefined) updateData.preferred_intents = updateDto.preferredIntents;
      if (updateDto.preferredDifficulty !== undefined) updateData.preferred_difficulty = updateDto.preferredDifficulty;
      if (updateDto.preferredDuration !== undefined) updateData.preferred_duration = updateDto.preferredDuration;

      await this.supabaseApi.patch('users', userId, updateData);

      this.logger.log(`用户分析数据更新成功: ${userId}`);
      return {
        message: '用户分析数据更新成功',
        userId,
      };
    } catch (error) {
      this.logger.error(`更新用户分析数据失败: ${userId}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取用户漏斗状态
   */
  @Get('users/:id/funnel')
  @ApiOperation({
    summary: '获取用户漏斗状态',
    description: '获取用户在产品使用漏斗中的当前状态',
  })
  @ApiParam({
    name: 'id',
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: UserFunnelResponseDto,
  })
  async getUserFunnel(@Param('id') userId: string): Promise<UserFunnelResponseDto> {
    try {
      this.logger.log(`获取用户漏斗状态: ${userId}`);

      // 获取用户基本信息
      const user = await this.supabaseApi.getById('users', userId);
      if (!user) {
        throw new Error('用户不存在');
      }

      // 获取用户的锻炼会话
      const sessions = await this.supabaseApi.get('workout_sessions', {
        user_id: userId,
      }, { orderBy: 'created_at.asc' });

      // 计算漏斗状态
      const daysSinceRegistration = Math.floor(
        (new Date().getTime() - new Date(user.created_at).getTime()) / (1000 * 60 * 60 * 24)
      );

      const completedSessions = sessions.filter(s => s.status === 'COMPLETED');
      const hasFirstWorkout = completedSessions.length > 0;
      const recentSessions = sessions.filter(s => {
        const sessionDate = new Date(s.created_at);
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return sessionDate >= thirtyDaysAgo;
      });

      // 计算活跃度评分
      let engagementScore = 0;
      if (hasFirstWorkout) engagementScore += 20;
      engagementScore += Math.min(user.current_streak * 5, 40);
      engagementScore += Math.min(recentSessions.length * 2, 40);

      const result: UserFunnelResponseDto = {
        userId,
        registrationStage: 'COMPLETED',
        firstWorkoutStage: hasFirstWorkout ? 'COMPLETED' : 'PENDING',
        retentionStage: recentSessions.length > 0 ? 'ACTIVE' : 'INACTIVE',
        engagementScore: Math.min(engagementScore, 100),
        daysSinceRegistration,
      };

      this.logger.log(`获取用户漏斗状态成功: ${userId}`);
      return result;
    } catch (error) {
      this.logger.error(`获取用户漏斗状态失败: ${userId}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取用户指标概览
   */
  @Get('users/:id/metrics')
  @ApiOperation({
    summary: '获取用户指标概览',
    description: '获取用户的关键指标统计概览',
  })
  @ApiParam({
    name: 'id',
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: UserMetricsResponseDto,
  })
  async getUserMetrics(@Param('id') userId: string): Promise<UserMetricsResponseDto> {
    try {
      this.logger.log(`获取用户指标概览: ${userId}`);

      // 获取用户基本信息
      const user = await this.supabaseApi.getById('users', userId);
      if (!user) {
        throw new Error('用户不存在');
      }

      // 获取锻炼会话统计
      const sessions = await this.supabaseApi.get('workout_sessions', {
        user_id: userId,
      });

      const completedSessions = sessions.filter(s => s.status === 'COMPLETED');

      // 计算本周和本月的锻炼次数
      const now = new Date();
      const weekStart = new Date(now);
      weekStart.setDate(now.getDate() - now.getDay());

      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

      const weeklyWorkouts = completedSessions.filter(s =>
        new Date(s.created_at) >= weekStart
      ).length;

      const monthlyWorkouts = completedSessions.filter(s =>
        new Date(s.created_at) >= monthStart
      ).length;

      // 计算平均锻炼时长
      const avgWorkoutDuration = completedSessions.length > 0
        ? Math.round(user.total_duration_sec / completedSessions.length / 60)
        : 0;

      const result: UserMetricsResponseDto = {
        userId,
        totalWorkouts: user.total_workouts || 0,
        totalDurationSec: user.total_duration_sec || 0,
        currentStreak: user.current_streak || 0,
        longestStreak: user.longest_streak || 0,
        avgWorkoutDuration,
        weeklyWorkouts,
        monthlyWorkouts,
      };

      this.logger.log(`获取用户指标概览成功: ${userId}`);
      return result;
    } catch (error) {
      this.logger.error(`获取用户指标概览失败: ${userId}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取用户每日指标
   */
  @Get('users/:id/daily')
  @ApiOperation({
    summary: '获取用户每日指标',
    description: '获取用户指定时间范围内的每日锻炼指标',
  })
  @ApiParam({
    name: 'id',
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  @ApiQuery({
    name: 'startDate',
    description: '开始日期（YYYY-MM-DD）',
    example: '2024-01-01',
    required: false,
  })
  @ApiQuery({
    name: 'endDate',
    description: '结束日期（YYYY-MM-DD）',
    example: '2024-01-31',
    required: false,
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: [DailyMetricsResponseDto],
  })
  async getUserDailyMetrics(
    @Param('id') userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ): Promise<DailyMetricsResponseDto[]> {
    try {
      this.logger.log(`获取用户每日指标: ${userId}, ${startDate} - ${endDate}`);

      // 设置默认日期范围（最近30天）
      const end = endDate ? new Date(endDate) : new Date();
      const start = startDate ? new Date(startDate) : new Date();
      if (!startDate) {
        start.setDate(end.getDate() - 30);
      }

      // 获取用户每日训练记录
      const filters: Record<string, any> = {
        user_id: userId,
      };

      const dailyTrainings = await this.supabaseApi.get('daily_trainings', filters, {
        orderBy: 'training_date.desc',
      });

      // 过滤日期范围
      const filteredTrainings = dailyTrainings.filter(training => {
        const trainingDate = new Date(training.training_date);
        return trainingDate >= start && trainingDate <= end;
      });

      const result = filteredTrainings.map(training => ({
        trainingDate: training.training_date,
        totalSessions: training.total_sessions || 0,
        totalDuration: training.total_duration || 0,
        totalExercises: training.total_exercises || 0,
        completedSessions: training.completed_sessions || 0,
        completionRate: training.total_sessions > 0
          ? training.completed_sessions / training.total_sessions
          : 0,
        isStreakDay: training.is_streak_day || false,
      }));

      this.logger.log(`获取用户每日指标成功: ${userId}, 共${result.length}条记录`);
      return result;
    } catch (error) {
      this.logger.error(`获取用户每日指标失败: ${userId}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取群组分析
   */
  @Get('cohorts')
  @ApiOperation({
    summary: '获取群组分析',
    description: '获取用户群组的留存和行为分析',
  })
  @ApiQuery({
    name: 'period',
    description: '分析周期（month/week）',
    example: 'month',
    required: false,
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: [CohortAnalysisResponseDto],
  })
  async getCohortAnalysis(@Query('period') period = 'month'): Promise<CohortAnalysisResponseDto[]> {
    try {
      this.logger.log(`获取群组分析: ${period}`);

      // 获取所有用户
      const users = await this.supabaseApi.get('users', {}, {
        orderBy: 'created_at.asc',
      });

      // 按注册月份分组
      const cohorts: Record<string, any[]> = {};
      users.forEach(user => {
        const cohortKey = new Date(user.created_at).toISOString().substring(0, 7); // YYYY-MM
        if (!cohorts[cohortKey]) {
          cohorts[cohortKey] = [];
        }
        cohorts[cohortKey].push(user);
      });

      // 计算每个群组的留存率
      const result: CohortAnalysisResponseDto[] = [];

      for (const [cohortKey, cohortUsers] of Object.entries(cohorts)) {
        const cohortStartDate = new Date(cohortKey + '-01');

        // 计算各个时间点的留存率
        const retention: Record<string, number> = {};

        const day1RetainedUsers = cohortUsers.filter(user => user.total_workouts > 0);
        retention.day_1 = day1RetainedUsers.length / cohortUsers.length;

        // 简化的留存计算（实际应该基于具体的活跃定义）
        retention.day_7 = retention.day_1 * 0.75;
        retention.day_30 = retention.day_1 * 0.5;

        // 计算平均LTV（简化计算）
        const totalWorkouts = cohortUsers.reduce((sum, user) => sum + (user.total_workouts || 0), 0);
        const averageLTV = totalWorkouts / cohortUsers.length;

        result.push({
          cohort: cohortKey,
          size: cohortUsers.length,
          retention,
          averageLTV,
        });
      }

      this.logger.log(`获取群组分析成功: 共${result.length}个群组`);
      return result.slice(-12); // 返回最近12个月的数据
    } catch (error) {
      this.logger.error('获取群组分析失败', error.stack);
      throw error;
    }
  }

  /**
   * 获取平台KPI指标
   */
  @Get('platform/kpis')
  @ApiOperation({
    summary: '获取平台KPI指标',
    description: '获取平台整体的关键性能指标',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: PlatformKPIResponseDto,
  })
  async getPlatformKPIs(): Promise<PlatformKPIResponseDto> {
    try {
      this.logger.log('获取平台KPI指标');

      // 并行获取各种数据
      const [users, sessions, scenarios, equipment] = await Promise.all([
        this.supabaseApi.get('users', {}),
        this.supabaseApi.get('workout_sessions', {}),
        this.supabaseApi.get('scenarios', {}),
        this.supabaseApi.get('equipment', {}),
      ]);

      // 计算活跃用户（过去30天有锻炼记录）
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const recentSessions = sessions.filter(s =>
        new Date(s.created_at) >= thirtyDaysAgo
      );
      const activeUserIds = new Set(recentSessions.map(s => s.user_id));

      // 计算新用户
      const newUsers = users.filter(u =>
        new Date(u.created_at) >= thirtyDaysAgo
      ).length;

      // 计算平均会话时长
      const completedSessions = sessions.filter(s => s.status === 'COMPLETED');
      const avgSessionDuration = completedSessions.length > 0
        ? completedSessions.reduce((sum, s) => sum + (s.actual_duration_sec || 0), 0) / completedSessions.length / 60
        : 0;

      // 计算留存率（简化）
      const totalUsers = users.length;
      const retentionRates = {
        day_1: activeUserIds.size / totalUsers,
        day_7: activeUserIds.size / totalUsers * 0.8,
        day_30: activeUserIds.size / totalUsers * 0.6,
      };

      // 统计最受欢迎的器材分类
      const equipmentCategories = equipment.reduce((acc, eq) => {
        const category = eq.category || 'NONE';
        acc[category] = (acc[category] || 0) + 1;
        return acc;
      }, {});

      const popularEquipmentCategories = Object.entries(equipmentCategories)
        .map(([category, count]) => ({ category, count: count as number }))
        .sort((a, b) => b.count - a.count);

      // 统计最受欢迎的场景
      const scenarioStats = scenarios.map(scenario => ({
        scenario: scenario.code,
        count: recentSessions.filter(s => s.target_muscle === scenario.code).length,
      })).sort((a, b) => b.count - a.count);

      const result: PlatformKPIResponseDto = {
        totalUsers: users.length,
        activeUsers: activeUserIds.size,
        newUsers,
        totalSessions: sessions.length,
        avgSessionDuration: Math.round(avgSessionDuration * 100) / 100,
        retentionRates,
        popularEquipmentCategories,
        popularScenarios: scenarioStats,
      };

      this.logger.log('获取平台KPI指标成功');
      return result;
    } catch (error) {
      this.logger.error('获取平台KPI指标失败', error.stack);
      throw error;
    }
  }

  /**
   * 批量更新每日指标
   */
  @Post('daily-metrics/batch')
  @ApiOperation({
    summary: '批量更新每日指标',
    description: '批量更新用户的每日锻炼指标',
  })
  @ApiBody({
    type: [BatchUpdateDailyMetricsDto],
    description: '每日指标数据数组',
  })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '更新成功',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: '批量更新成功' },
        updated: { type: 'number', example: 10 },
        failed: { type: 'number', example: 0 },
      },
    },
  })
  async batchUpdateDailyMetrics(@Body() metricsData: BatchUpdateDailyMetricsDto[]) {
    try {
      this.logger.log(`批量更新每日指标: ${metricsData.length}条记录`);

      let updated = 0;
      let failed = 0;

      for (const metrics of metricsData) {
        try {
          // 检查记录是否已存在
          const existing = await this.supabaseApi.get('daily_trainings', {
            user_id: metrics.userId,
            training_date: metrics.trainingDate,
          }, { limit: 1 });

          const data = {
            user_id: metrics.userId,
            training_date: metrics.trainingDate,
            total_sessions: metrics.totalSessions || 0,
            total_duration: metrics.totalDuration || 0,
            total_exercises: metrics.totalExercises || 0,
            completed_sessions: metrics.completedSessions || 0,
            is_streak_day: metrics.isStreakDay || false,
            updated_at: new Date().toISOString(),
          };

          if (existing && existing.length > 0) {
            // 更新现有记录
            await this.supabaseApi.patch('daily_trainings', existing[0].id, data);
          } else {
            // 创建新记录
            const cuidId = `cuid_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
            await this.supabaseApi.post('daily_trainings', {
              id: cuidId,
              ...data,
              created_at: new Date().toISOString(),
            });
          }

          updated++;
        } catch (error) {
          this.logger.error(`更新每日指标失败: ${metrics.userId} ${metrics.trainingDate}`, error.message);
          failed++;
        }
      }

      this.logger.log(`批量更新每日指标完成: 成功${updated}, 失败${failed}`);

      return {
        message: '批量更新完成',
        updated,
        failed,
      };
    } catch (error) {
      this.logger.error('批量更新每日指标失败', error.stack);
      throw error;
    }
  }
}
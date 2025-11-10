import { Injectable, Logger, NotFoundException, ConflictException } from '@nestjs/common';
import { ThemeWeeksDao } from './theme-weeks.dao';
import {
  CurrentThemeWeekDto,
  JoinThemeWeekDto,
  JoinThemeWeekResponseDto,
  ThemeWeekParticipationDto
} from './dto/theme-week.dto';

@Injectable()
export class ThemeWeeksService {
  private readonly logger = new Logger(ThemeWeeksService.name);

  constructor(private readonly themeWeeksDao: ThemeWeeksDao) {
    this.logger.log('ThemeWeeksService initialized');
  }

  /**
   * 获取当前主题周信息（包含用户参与状态）
   */
  async getCurrentThemeWeek(userId?: string): Promise<CurrentThemeWeekDto> {
    try {
      // 获取当前活跃的主题周
      const currentThemeWeek = await this.themeWeeksDao.getCurrentThemeWeek();

      // 获取即将到来的主题周预览
      const upcomingThemeWeeks = await this.themeWeeksDao.getUpcomingThemeWeeks();

      if (!currentThemeWeek) {
        return {
          current: null,
          upcoming: upcomingThemeWeeks.map(tw => ({
            title: tw.title,
            equipmentCode: tw.equipmentCode,
            startDate: tw.startDate.toISOString(),
          })),
          message: 'No active theme week at the moment',
        };
      }

      // 构建基础响应
      let currentWithParticipation: any = {
        id: currentThemeWeek.id,
        code: currentThemeWeek.code,
        title: currentThemeWeek.title,
        description: currentThemeWeek.description,
        equipmentCode: currentThemeWeek.equipmentCode,
        startDate: currentThemeWeek.startDate,
        endDate: currentThemeWeek.endDate,
        targetExerciseCount: currentThemeWeek.targetExerciseCount,
        rewardType: currentThemeWeek.rewardType,
        rewardData: currentThemeWeek.rewardData,
        globalStats: {
          totalParticipants: currentThemeWeek.totalParticipants,
          completionRate: currentThemeWeek.completionRate,
        },
      };

      // 如果提供了userId，获取用户参与信息
      if (userId) {
        const participation = await this.themeWeeksDao.getUserParticipation(userId, currentThemeWeek.id);

        if (participation) {
          // 计算剩余时间
          const timeLeft = this.calculateTimeLeft(currentThemeWeek.endDate);

          currentWithParticipation.participation = {
            isJoined: true,
            progress: {
              completed: participation.exercisesCompleted,
              target: participation.targetExercises,
              percentage: participation.progressPercent,
            },
            timeLeft,
          };
        } else {
          currentWithParticipation.participation = {
            isJoined: false,
            progress: {
              completed: 0,
              target: currentThemeWeek.targetExerciseCount,
              percentage: 0,
            },
            timeLeft: this.calculateTimeLeft(currentThemeWeek.endDate),
          };
        }
      }

      return {
        current: currentWithParticipation,
        upcoming: upcomingThemeWeeks.map(tw => ({
          title: tw.title,
          equipmentCode: tw.equipmentCode,
          startDate: tw.startDate.toISOString(),
        })),
      };
    } catch (error) {
      this.logger.error('Failed to get current theme week', error);
      throw error;
    }
  }

  /**
   * 用户加入主题周
   */
  async joinThemeWeek(themeWeekId: string, joinDto: JoinThemeWeekDto): Promise<JoinThemeWeekResponseDto> {
    try {
      // 检查主题周是否存在且活跃
      const themeWeek = await this.themeWeeksDao.getThemeWeekWithParticipation(themeWeekId);

      if (!themeWeek) {
        throw new NotFoundException('Theme week not found');
      }

      if (themeWeek.status !== 'ACTIVE') {
        return {
          success: false,
          message: 'This theme week is not active',
          error: {
            code: 'THEME_WEEK_NOT_ACTIVE',
            message: 'This theme week is not currently active',
          },
        };
      }

      // 检查是否已过期
      const now = new Date();
      if (themeWeek.endDate < now) {
        return {
          success: false,
          message: 'This theme week has ended',
          error: {
            code: 'THEME_WEEK_ENDED',
            message: 'This theme week has already ended',
          },
        };
      }

      // 检查用户是否已经加入
      const hasJoined = await this.themeWeeksDao.hasUserJoinedThemeWeek(joinDto.userId, themeWeekId);

      if (hasJoined) {
        return {
          success: false,
          message: 'You have already joined this theme week',
          error: {
            code: 'ALREADY_JOINED',
            message: 'You have already joined this theme week',
          },
        };
      }

      // 创建参与记录
      const participation = await this.themeWeeksDao.createParticipation(
        joinDto.userId,
        themeWeekId,
        themeWeek.targetExerciseCount,
      );

      // 更新主题周统计信息
      await this.themeWeeksDao.updateThemeWeekStats(themeWeekId);

      return {
        success: true,
        participation: {
          id: participation.id,
          userId: participation.userId,
          themeWeekId: participation.themeWeekId,
          status: participation.status,
          joinedAt: participation.joinedAt,
          completedAt: participation.completedAt,
          exercisesCompleted: participation.exercisesCompleted,
          targetExercises: participation.targetExercises,
          progressPercent: participation.progressPercent,
          rewardEarned: participation.rewardEarned,
          rewardClaimedAt: participation.rewardClaimedAt,
          relatedSessions: participation.relatedSessions,
        },
        message: `Successfully joined ${themeWeek.title} challenge!`,
      };
    } catch (error) {
      this.logger.error(`Failed to join theme week ${themeWeekId}`, error);

      if (error instanceof NotFoundException || error instanceof ConflictException) {
        throw error;
      }

      throw new Error(`Failed to join theme week: ${error.message}`);
    }
  }

  /**
   * 更新用户主题周进度（当用户完成相关练习时调用）
   */
  async updateUserProgress(userId: string, themeWeekId: string, exercisesCompleted: number) {
    try {
      const updatedParticipation = await this.themeWeeksDao.updateParticipationProgress(
        userId,
        themeWeekId,
        exercisesCompleted,
      );

      // 如果用户完成了挑战，更新主题周统计
      if (updatedParticipation.status === 'COMPLETED') {
        await this.themeWeeksDao.updateThemeWeekStats(themeWeekId);
      }

      return updatedParticipation;
    } catch (error) {
      this.logger.error(`Failed to update user progress for theme week ${themeWeekId}`, error);
      throw error;
    }
  }

  /**
   * 计算剩余时间的人性化显示
   */
  private calculateTimeLeft(endDate: Date): string {
    const now = new Date();
    const diffMs = endDate.getTime() - now.getTime();

    if (diffMs <= 0) {
      return 'Ended';
    }

    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    const diffHours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));

    if (diffDays > 0) {
      return `${diffDays} day${diffDays > 1 ? 's' : ''}${diffHours > 0 ? ` ${diffHours} hour${diffHours > 1 ? 's' : ''}` : ''}`;
    } else if (diffHours > 0) {
      return `${diffHours} hour${diffHours > 1 ? 's' : ''}`;
    } else {
      const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
      return `${diffMinutes} minute${diffMinutes > 1 ? 's' : ''}`;
    }
  }
}
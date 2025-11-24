import { Injectable, Logger } from '@nestjs/common';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { SessionStatus } from '../common/types/prisma-enums';
import { logger } from '../common/logger/logger';

/**
 * WorkoutSessions DAO 类
 * 使用 Supabase API 进行数据库操作
 */
@Injectable()
export class WorkoutSessionsDao {
  constructor(private readonly supabaseApi: SupabaseApiService) {
    logger.info('WorkoutSessionsDao initialized with Supabase API');
  }

  /**
   * 创建训练会话和关联的动作
   * @param sessionData 会话数据
   * @returns 创建的会话
   */
  async createSessionWithExercises(sessionData: any) {
    try {
      const { exercises } = sessionData;

      // 生成CUID ID
      const sessionId = `session_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

      // 创建会话数据
      const sessionCreateData = {
        id: sessionId,
        user_id: sessionData.userId,
        intent_type: sessionData.intentType,
        scenario_id: sessionData.scenarioId || null,
        target_muscles: sessionData.targetMuscles || [],
        total_duration: sessionData.totalDuration || 0,
        actual_duration: null,
        difficulty: sessionData.difficulty || 'GREEN',
        is_silent: sessionData.isSilent || false,
        theme_week_id: sessionData.themeWeekId || null,
        status: 'PENDING',
        started_at: null,
        completed_at: null,
        rating: null,
        feedback: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      // 创建会话
      await this.supabaseApi.post('workout_sessions', sessionCreateData);

      // 创建会话动作关联
      if (exercises && exercises.length > 0) {
        const sessionExercisesData = exercises.map((exercise: any) => ({
          id: `se_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`,
          workout_session_id: sessionId,
          exercise_id: exercise.exerciseId,
          sequence_order: exercise.sequenceOrder,
          duration: exercise.duration,
          sets: exercise.sets || 1,
          is_completed: false,
          started_at: null,
          ended_at: null,
          user_rating: null,
          user_feedback: null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }));

        for (const seData of sessionExercisesData) {
          await this.supabaseApi.post('session_exercises', seData);
        }
      }

      // 获取完整的会话数据（包含关联）
      return await this.findSessionById(sessionId, true);
    } catch (error) {
      logger.error(`创建训练会话失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.CREATE_FAILED, error, { sessionData });
    }
  }

  /**
   * 根据ID获取训练会话
   * @param id 会话ID
   * @param includeExercises 是否包含动作信息
   * @returns 训练会话
   */
  async findSessionById(id: string, includeExercises: boolean = true) {
    try {
      const session = await this.supabaseApi.getById('workout_sessions', id);

      if (!session) {
        return null;
      }

      // 转换为camelCase格式
      const formattedSession: any = {
        id: session.id,
        userId: session.user_id,
        intentType: session.intent_type,
        scenarioId: session.scenario_id,
        targetMuscles: session.target_muscles || [],
        totalDuration: session.total_duration || 0,
        actualDuration: session.actual_duration,
        difficulty: session.difficulty,
        isSilent: session.is_silent || false,
        themeWeekId: session.theme_week_id,
        status: session.status,
        startedAt: session.started_at,
        completedAt: session.completed_at,
        rating: session.rating,
        feedback: session.feedback,
        createdAt: session.created_at,
        updatedAt: session.updated_at,
      };

      // 获取场景信息
      if (session.scenario_id) {
        try {
          const scenario = await this.supabaseApi.getById('scenarios', session.scenario_id);
          if (scenario) {
            formattedSession.scenario = {
              id: scenario.id,
              code: scenario.code,
              name: scenario.name,
              description: scenario.description,
            };
          }
        } catch (err) {
          logger.warn(`获取场景信息失败: ${err.message}`);
        }
      }

      // 获取会话动作
      if (includeExercises) {
        try {
          const sessionExercises = await this.supabaseApi.get('session_exercises', {
            workout_session_id: id,
          }, {
            orderBy: 'sequence_order.asc',
          });

          formattedSession.sessionExercises = [];

          for (const se of sessionExercises) {
            const exerciseData: any = {
              id: se.id,
              exerciseId: se.exercise_id,
              sequenceOrder: se.sequence_order,
              duration: se.duration,
              sets: se.sets,
              isCompleted: se.is_completed || false,
              startedAt: se.started_at,
              endedAt: se.ended_at,
              userRating: se.user_rating,
              userFeedback: se.user_feedback,
            };

            // 获取动作详情
            try {
              const exercise = await this.supabaseApi.getById('exercises', se.exercise_id);
              if (exercise) {
                exerciseData.exercise = {
                  id: exercise.id,
                  code: exercise.code,
                  name: exercise.name,
                  description: exercise.description,
                  primaryMuscle: exercise.primary_muscle,
                  secondaryMuscles: exercise.secondary_muscles || [],
                  difficulty: exercise.difficulty,
                  durationSeconds: exercise.duration_seconds,
                  demoImageUrl: exercise.demo_image_url,
                  thumbnailUrl: exercise.thumbnail_url,
                };
              }
            } catch (err) {
              logger.warn(`获取动作详情失败: ${err.message}`);
            }

            formattedSession.sessionExercises.push(exerciseData);
          }
        } catch (err) {
          logger.warn(`获取会话动作失败: ${err.message}`);
          formattedSession.sessionExercises = [];
        }
      }

      return formattedSession;
    } catch (error) {
      logger.error(`根据ID获取训练会话失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { sessionId: id });
    }
  }

  /**
   * 获取用户的训练会话列表
   * @param userId 用户ID
   * @param filters 筛选条件
   * @returns 会话列表
   */
  async findUserSessions(
    userId: string,
    filters?: {
      status?: string;
      fromDate?: Date;
      toDate?: Date;
      limit?: number;
      offset?: number;
    }
  ) {
    try {
      const whereFilters: Record<string, any> = {
        user_id: userId,
      };

      if (filters?.status) {
        whereFilters.status = filters.status;
      }

      // Note: Supabase API doesn't support date range filters directly
      // We'll fetch all and filter in memory for now
      const limit = filters?.limit || 50;
      const offset = filters?.offset || 0;

      const sessions = await this.supabaseApi.get('workout_sessions', whereFilters, {
        limit,
        offset,
        orderBy: 'completed_at.desc.nullslast,created_at.desc',
      });

      // Filter by date range if specified
      let filteredSessions = sessions;
      if (filters?.fromDate || filters?.toDate) {
        filteredSessions = sessions.filter((session: any) => {
          if (!session.completed_at) return false;
          const completedAt = new Date(session.completed_at);
          if (filters.fromDate && completedAt < filters.fromDate) return false;
          if (filters.toDate && completedAt > filters.toDate) return false;
          return true;
        });
      }

      // Format and enrich sessions
      const formattedSessions = [];
      for (const session of filteredSessions) {
        const formattedSession: any = {
          id: session.id,
          userId: session.user_id,
          intentType: session.intent_type,
          scenarioId: session.scenario_id,
          targetMuscles: session.target_muscles || [],
          totalDuration: session.total_duration || 0,
          actualDuration: session.actual_duration,
          difficulty: session.difficulty,
          status: session.status,
          completedAt: session.completed_at,
          createdAt: session.created_at,
        };

        // Get session exercises
        try {
          const sessionExercises = await this.supabaseApi.get('session_exercises', {
            workout_session_id: session.id,
          }, {
            orderBy: 'sequence_order.asc',
          });

          formattedSession.sessionExercises = [];

          for (const se of sessionExercises) {
            const exerciseData: any = {
              id: se.id,
              exerciseId: se.exercise_id,
              sequenceOrder: se.sequence_order,
              duration: se.duration,
            };

            // Get exercise details
            try {
              const exercise = await this.supabaseApi.getById('exercises', se.exercise_id);
              if (exercise) {
                exerciseData.exercise = {
                  id: exercise.id,
                  name: exercise.name,
                  thumbnailUrl: exercise.thumbnail_url,
                };
              }
            } catch (err) {
              logger.warn(`获取动作详情失败: ${err.message}`);
            }

            formattedSession.sessionExercises.push(exerciseData);
          }
        } catch (err) {
          logger.warn(`获取会话动作失败: ${err.message}`);
          formattedSession.sessionExercises = [];
        }

        // Get scenario
        if (session.scenario_id) {
          try {
            const scenario = await this.supabaseApi.getById('scenarios', session.scenario_id);
            if (scenario) {
              formattedSession.scenario = {
                id: scenario.id,
                name: scenario.name,
              };
            }
          } catch (err) {
            logger.warn(`获取场景信息失败: ${err.message}`);
          }
        }

        formattedSessions.push(formattedSession);
      }

      return formattedSessions;
    } catch (error) {
      logger.error(`获取用户训练会话失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { userId, filters });
    }
  }

  /**
   * 更新训练会话
   * @param id 会话ID
   * @param updateData 更新数据
   * @returns 更新后的会话
   */
  async updateSession(id: string, updateData: any) {
    try {
      // Convert camelCase to snake_case
      const updatePayload: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateData.status !== undefined) updatePayload.status = updateData.status;
      if (updateData.startedAt !== undefined) updatePayload.started_at = updateData.startedAt;
      if (updateData.completedAt !== undefined) updatePayload.completed_at = updateData.completedAt;
      if (updateData.actualDuration !== undefined) updatePayload.actual_duration = updateData.actualDuration;
      if (updateData.rating !== undefined) updatePayload.rating = updateData.rating;
      if (updateData.feedback !== undefined) updatePayload.feedback = updateData.feedback;

      await this.supabaseApi.patch('workout_sessions', id, updatePayload);

      return await this.findSessionById(id, false);
    } catch (error) {
      logger.error(`更新训练会话失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.UPDATE_FAILED, error, { sessionId: id, updateData });
    }
  }

  /**
   * 更新会话动作
   * @param sessionId 会话ID
   * @param exerciseId 动作ID
   * @param updateData 更新数据
   * @returns 更新后的会话动作
   */
  async updateSessionExercise(sessionId: string, exerciseId: string, updateData: any) {
    try {
      // First find the session exercise
      const sessionExercises = await this.supabaseApi.get('session_exercises', {
        workout_session_id: sessionId,
        exercise_id: exerciseId,
      });

      if (!sessionExercises || sessionExercises.length === 0) {
        throw new Error(`SessionExercise not found for sessionId=${sessionId}, exerciseId=${exerciseId}`);
      }

      const sessionExercise = sessionExercises[0];

      // Convert camelCase to snake_case
      const updatePayload: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateData.isCompleted !== undefined) updatePayload.is_completed = updateData.isCompleted;
      if (updateData.startedAt !== undefined) updatePayload.started_at = updateData.startedAt;
      if (updateData.endedAt !== undefined) updatePayload.ended_at = updateData.endedAt;
      if (updateData.userRating !== undefined) updatePayload.user_rating = updateData.userRating;
      if (updateData.userFeedback !== undefined) updatePayload.user_feedback = updateData.userFeedback;

      const updated = await this.supabaseApi.patch('session_exercises', sessionExercise.id, updatePayload);

      // Return formatted data
      return {
        id: updated.id,
        exerciseId: updated.exercise_id,
        isCompleted: updated.is_completed,
        startedAt: updated.started_at,
        endedAt: updated.ended_at,
        userRating: updated.user_rating,
        userFeedback: updated.user_feedback,
        updatedAt: updated.updated_at,
      };
    } catch (error) {
      logger.error(`更新会话动作失败: sessionId=${sessionId}, exerciseId=${exerciseId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.UPDATE_FAILED, error, { sessionId, exerciseId, updateData });
    }
  }

  /**
   * 获取用户训练统计
   * @param userId 用户ID
   * @param days 统计天数
   * @returns 统计数据
   */
  async getUserStats(userId: string, days: number = 30) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      // Get all completed sessions
      const allSessions = await this.supabaseApi.get('workout_sessions', {
        user_id: userId,
        status: SessionStatus.COMPLETED,
      }, {
        orderBy: 'completed_at.desc',
      });

      // Filter by date
      const sessions = allSessions.filter((session: any) => {
        if (!session.completed_at) return false;
        return new Date(session.completed_at) >= cutoffDate;
      });

      const totalSessions = sessions.length;
      const totalDuration = sessions.reduce((sum: number, session: any) => sum + (session.actual_duration || 0), 0);

      // 计算连击天数
      const streak = await this.calculateStreak(userId);

      return {
        totalSessions,
        totalDuration,
        averageDuration: totalSessions > 0 ? Math.round(totalDuration / totalSessions) : 0,
        currentStreak: streak,
        recentSessions: sessions.slice(0, 10).map((s: any) => ({
          id: s.id,
          completedAt: s.completed_at,
          actualDuration: s.actual_duration,
          status: s.status,
        })),
      };
    } catch (error) {
      logger.error(`获取用户训练统计失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { userId });
    }
  }

  /**
   * 计算用户连击天数
   * @param userId 用户ID
   * @returns 连击天数
   */
  private async calculateStreak(userId: string): Promise<number> {
    try {
      // Get completed sessions
      const sessions = await this.supabaseApi.get('workout_sessions', {
        user_id: userId,
        status: SessionStatus.COMPLETED,
      }, {
        orderBy: 'completed_at.desc',
        limit: 365,
      });

      if (sessions.length === 0) return 0;

      // Get unique days
      const uniqueDays = Array.from(new Set(
        sessions
          .filter((s: any) => s.completed_at)
          .map((s: any) => new Date(s.completed_at).toISOString().split('T')[0])
      )).sort((a, b) => (b as string).localeCompare(a as string));

      // Calculate streak
      let streak = 0;
      const today = new Date().toISOString().split('T')[0];
      let currentDate = today;

      for (const day of uniqueDays) {
        if (day === currentDate) {
          streak++;
          const date = new Date(currentDate);
          date.setDate(date.getDate() - 1);
          currentDate = date.toISOString().split('T')[0];
        } else {
          break;
        }
      }

      return streak;
    } catch (error) {
      logger.error(`计算连击天数失败: userId=${userId}, error=${error.message}`);
      return 0;
    }
  }

  /**
   * 获取活跃会话数量
   * @returns 活跃会话数量
   */
  async getActiveSessionsCount(): Promise<number> {
    try {
      const sessions = await this.supabaseApi.get('workout_sessions', {}, {
        limit: 1000,
      });

      const activeCount = sessions.filter((s: any) =>
        s.status === 'PENDING' || s.status === 'IN_PROGRESS'
      ).length;

      return activeCount;
    } catch (error) {
      logger.error(`获取活跃会话数量失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取今日完成的会话数量
   * @returns 今日完成会话数量
   */
  async getTodayCompletedCount(): Promise<number> {
    try {
      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());

      const sessions = await this.supabaseApi.get('workout_sessions', {
        status: SessionStatus.COMPLETED,
      }, {
        limit: 1000,
      });

      const todayCount = sessions.filter((s: any) => {
        if (!s.completed_at) return false;
        return new Date(s.completed_at) >= todayStart;
      }).length;

      return todayCount;
    } catch (error) {
      logger.error(`获取今日完成会话数量失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取用户最常训练的动作
   * @param userId 用户ID
   * @param limit 返回数量限制
   * @returns 最常训练的动作列表
   */
  async getUserMostTrainedExercises(userId: string, limit: number = 6) {
    try {
      // Get all completed sessions for the user
      const sessions = await this.supabaseApi.get('workout_sessions', {
        user_id: userId,
        status: 'COMPLETED',
      });

      if (sessions.length === 0) {
        return [];
      }

      const sessionIds = sessions.map((s: any) => s.id);

      // Get all session exercises for these sessions
      const allSessionExercises: any[] = [];
      for (const sessionId of sessionIds) {
        const se = await this.supabaseApi.get('session_exercises', {
          workout_session_id: sessionId,
        });
        allSessionExercises.push(...se);
      }

      // Count exercise occurrences
      const exerciseCounts = new Map<string, number>();
      const exerciseLastTrainedAt = new Map<string, string>();

      for (const se of allSessionExercises) {
        const exerciseId = se.exercise_id;
        exerciseCounts.set(exerciseId, (exerciseCounts.get(exerciseId) || 0) + 1);

        // Find the session for this exercise
        const session = sessions.find((s: any) => s.id === se.workout_session_id);
        if (session?.completed_at) {
          const currentLast = exerciseLastTrainedAt.get(exerciseId);
          if (!currentLast || session.completed_at > currentLast) {
            exerciseLastTrainedAt.set(exerciseId, session.completed_at);
          }
        }
      }

      // Sort by count and get top exercises
      const sortedExercises = Array.from(exerciseCounts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit);

      // Get exercise details
      const result = [];
      for (const [exerciseId, count] of sortedExercises) {
        try {
          const exercise = await this.supabaseApi.getById('exercises', exerciseId);
          if (exercise && exercise.is_active) {
            result.push({
              id: exercise.id,
              code: exercise.code,
              name: exercise.name,
              description: exercise.description,
              primaryMuscle: exercise.primary_muscle,
              difficulty: exercise.difficulty,
              durationSeconds: exercise.duration_seconds,
              demoImageUrl: exercise.demo_image_url,
              thumbnailUrl: exercise.thumbnail_url,
              trainedCount: count,
              lastTrainedAt: exerciseLastTrainedAt.get(exerciseId),
            });
          }
        } catch (err) {
          logger.warn(`获取动作详情失败: exerciseId=${exerciseId}, error=${err.message}`);
        }
      }

      logger.debug(`获取用户最常训练动作成功: userId=${userId}, count=${result.length}`);
      return result;
    } catch (error) {
      logger.error(`获取用户最常训练动作失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(
        ErrorCodes.DATABASE.QUERY_ERROR,
        error,
        { userId, limit }
      );
    }
  }
}

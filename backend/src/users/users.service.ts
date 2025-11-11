import { Injectable } from '@nestjs/common';
import { PasswordService } from '../auth/password.service';
import { ChangePasswordInput } from './dto/change-password.input';
import { UpdateUserInput } from './dto/update-user.input';
import { UserEntity } from '../common/types/user.types';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';

@Injectable()
export class UsersService {
  constructor(
    private supabaseApi: SupabaseApiService,
    private passwordService: PasswordService,
  ) {
    logger.info('UsersService initialized with SupabaseApiService');
  }

  /**
   * 根据用户ID查找用户（用于JWT认证）
   */
  async findOne(userId: string): Promise<UserEntity | null> {
    try {
      logger.info(`查找用户: ${userId}`);

      const item = await this.supabaseApi.getById('users', userId);

      if (!item) {
        logger.warn(`用户未找到: ${userId}`);
        return null;
      }

      const userEntity = new UserEntity({
        id: item.id,
        email: item.email,
        password: item.password,
        name: item.name,
        avatarUrl: item.avatar_url,
        totalWorkouts: item.total_workouts,
        totalDurationSec: item.total_duration_sec,
        currentStreak: item.current_streak,
        longestStreak: item.longest_streak,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      });

      logger.info(`成功找到用户: ${userId}`);
      return userEntity;
    } catch (error) {
      // 对于 JWT 认证，如果出现错误，返回 null 而不是抛出异常
      logger.error(`查找用户失败: ${userId}`, error.message);
      return null;
    }
  }

  /**
   * 根据Supabase Auth ID查找用户
   */
  async findBySupabaseAuthId(supabaseAuthId: string): Promise<UserEntity> {
    try {
      logger.info(`根据Supabase Auth ID查找用户: ${supabaseAuthId}`);

      const item = await this.supabaseApi.getById('users', supabaseAuthId);

      if (!item) {
        throw new ResponseError(ErrorCodes.USER.NOT_FOUND, undefined, {
          supabaseAuthId: supabaseAuthId,
        });
      }

      const userEntity = new UserEntity({
        id: item.id,
        email: item.email,
        password: item.password,
        name: item.name,
        avatarUrl: item.avatar_url,
        totalWorkouts: item.total_workouts,
        totalDurationSec: item.total_duration_sec,
        currentStreak: item.current_streak,
        longestStreak: item.longest_streak,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      });

      logger.info(`成功找到用户: ${supabaseAuthId}`);
      return userEntity;
    } catch (error) {
      this.handleError(error, 'findBySupabaseAuthId', { supabaseAuthId });
    }
  }

  /**
   * 根据邮箱查找用户
   */
  async findByEmail(email: string): Promise<UserEntity> {
    try {
      logger.info(`根据邮箱查找用户: ${email}`);

      const users = await this.supabaseApi.get('users', { email });

      if (!users || users.length === 0) {
        throw new ResponseError(ErrorCodes.USER.NOT_FOUND, undefined, {
          email: email,
        });
      }

      const item = users[0]; // 获取第一个匹配的用户

      const userEntity = new UserEntity({
        id: item.id,
        email: item.email,
        password: item.password,
        name: item.name,
        avatarUrl: item.avatar_url,
        totalWorkouts: item.total_workouts,
        totalDurationSec: item.total_duration_sec,
        currentStreak: item.current_streak,
        longestStreak: item.longest_streak,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      });

      logger.info(`成功找到用户: ${email}`);
      return userEntity;
    } catch (error) {
      this.handleError(error, 'findByEmail', { email });
    }
  }

  /**
   * 创建新用户
   */
  async createUser(userData: {
    id: string;
    email?: string;
    name?: string;
    avatarUrl?: string;
  }): Promise<UserEntity> {
    try {
      logger.info(`创建新用户: ${userData.email || userData.id}`);

      // 检查用户是否已存在
      try {
        const existingUser = await this.supabaseApi.getById('users', userData.id);
        if (existingUser) {
          throw new ResponseError(ErrorCodes.USER.ALREADY_EXISTS, undefined, {
            userId: userData.id,
          });
        }
      } catch (error) {
        // 如果是 NOT_FOUND 错误，继续创建；其他错误重新抛出
        if (!(error instanceof ResponseError) || error.code !== ErrorCodes.USER.NOT_FOUND.code) {
          throw error;
        }
      }

      const createData = {
        id: userData.id,
        email: userData.email || null,
        name: userData.name || null,
        avatar_url: userData.avatarUrl || null,
        total_workouts: 0,
        total_duration_sec: 0,
        current_streak: 0,
        longest_streak: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      const newUser = await this.supabaseApi.post('users', createData);

      const userEntity = new UserEntity({
        id: newUser.id,
        email: newUser.email,
        password: newUser.password,
        name: newUser.name,
        avatarUrl: newUser.avatar_url,
        totalWorkouts: newUser.total_workouts,
        totalDurationSec: newUser.total_duration_sec,
        currentStreak: newUser.current_streak,
        longestStreak: newUser.longest_streak,
        createdAt: newUser.created_at,
        updatedAt: newUser.updated_at,
      });

      logger.info(`成功创建用户: ${userData.email || userData.id}`);
      return userEntity;
    } catch (error) {
      this.handleError(error, 'createUser', { userData });
    }
  }

  /**
   * 更新用户信息
   */
  async updateUser(userId: string, newUserData: UpdateUserInput): Promise<UserEntity> {
    try {
      logger.info(`更新用户信息: ${userId}`);

      // 首先检查用户是否存在
      const existingUser = await this.supabaseApi.getById('users', userId);
      if (!existingUser) {
        throw new ResponseError(ErrorCodes.USER.NOT_FOUND, undefined, {
          userId: userId,
        });
      }

      const updateData = {
        firstname: newUserData.firstname,
        lastname: newUserData.lastname,
        updated_at: new Date().toISOString(),
      };

      const updatedUser = await this.supabaseApi.patch('users', userId, updateData);

      const userEntity = new UserEntity({
        id: updatedUser.id,
        email: updatedUser.email,
        password: updatedUser.password,
        name: updatedUser.name,
        avatarUrl: updatedUser.avatar_url,
        totalWorkouts: updatedUser.total_workouts,
        totalDurationSec: updatedUser.total_duration_sec,
        currentStreak: updatedUser.current_streak,
        longestStreak: updatedUser.longest_streak,
        createdAt: updatedUser.created_at,
        updatedAt: updatedUser.updated_at,
      });

      logger.info(`成功更新用户信息: ${userId}`);
      return userEntity;
    } catch (error) {
      this.handleError(error, 'updateUser', { userId, newUserData });
    }
  }

  /**
   * 修改密码
   */
  async changePassword(
    userId: string,
    userPassword: string,
    changePassword: ChangePasswordInput,
  ): Promise<void> {
    try {
      logger.info(`修改密码: ${userId}`);

      // 首先检查用户是否存在
      const existingUser = await this.supabaseApi.getById('users', userId);
      if (!existingUser) {
        throw new ResponseError(ErrorCodes.USER.NOT_FOUND, undefined, {
          userId: userId,
        });
      }

      // 验证当前密码
      if (existingUser.password) {
        const isValidPassword = await this.passwordService.validatePassword(
          changePassword.oldPassword,
          existingUser.password
        );

        if (!isValidPassword) {
          throw new ResponseError(ErrorCodes.USER.PASSWORD_INVALID, undefined, {
            userId: userId,
          });
        }
      }

      // 加密新密码
      const hashedNewPassword = await this.passwordService.hashPassword(changePassword.newPassword);

      // 更新密码
      await this.supabaseApi.patch('users', userId, {
        password: hashedNewPassword,
        updated_at: new Date().toISOString(),
      });

      logger.info(`成功修改密码: ${userId}`);
    } catch (error) {
      this.handleError(error, 'changePassword', { userId });
    }
  }

  /**
   * 错误处理统一方法
   */
  private handleError(error: any, method: string, context: any): never {
    logger.error(`UsersService.${method} error:`, error.stack);

    if (error instanceof ResponseError) {
      throw error;
    }

    // 如果是 Supabase API 错误，包装成 ResponseError
    throw new ResponseError(ErrorCodes.USER.INVALID_USER_ID, error, context);
  }
}
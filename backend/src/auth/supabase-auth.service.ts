import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AvatarGenerator } from '../common/utils/avatar-generator.util';
import { JwtService } from '@nestjs/jwt';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { RegisterDto, LoginDto, OtpLoginDto, VerifyOtpDto, GoogleOAuthDto } from './dto/auth.dto';
import { AuthResponseDto, OtpResponseDto, UserResponseDto } from './dto/auth-response.dto';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';


@Injectable()
export class SupabaseAuthService {
  // private readonly logger = new Logger(SupabaseAuthService.name);
  private readonly supabaseUrl: string;
  private readonly supabaseAnonKey: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
    private readonly supabaseApi: SupabaseApiService,
  ) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    this.supabaseAnonKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (!this.supabaseUrl || !this.supabaseAnonKey) {
      throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
    }
  }

  /**
   * 用户注册
   */
  async register(registerDto: RegisterDto): Promise<AuthResponseDto> {
    try {
      logger.info(`用户注册: ${registerDto.email}`);

      // 使用 Supabase Auth API 注册
      const authResponse = await this.callSupabaseAuth('/auth/v1/signup', {
        email: registerDto.email,
        password: registerDto.password,
        data: {
          name: registerDto.name || '',
        },
      });

      // 打印完整响应用于调试
      logger.info(`Supabase signup response: ${JSON.stringify(authResponse)}`);

      // 检查是否有错误
      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        logger.error(`Supabase signup error: ${JSON.stringify(authResponse)}`);
        throw new ResponseError(ErrorCodes.AUTH.REGISTRATION_FAILED);
      }

      // Supabase signup API 直接返回 user 对象，不是嵌套的 { user: {...} }
      const userFromSupabase = authResponse.user || authResponse;

      // 检查用户 ID 是否存在
      if (!userFromSupabase.id) {
        logger.error(`Supabase signup response missing user id: ${JSON.stringify(authResponse)}`);
        throw new ResponseError(ErrorCodes.AUTH.REGISTRATION_FAILED);
      }

      // 检查邮箱确认状态
      if (userFromSupabase.email_confirmed_at === null || userFromSupabase.confirmed_at === null) {
        logger.warn(`⚠️ 用户邮箱未确认: ${registerDto.email}，Supabase可能要求邮箱确认后才能登录`);
      }

      // 创建或更新用户记录到我们的数据库
      const user = await this.createOrUpdateUser({
        id: userFromSupabase.id,
        email: userFromSupabase.email,
        name: registerDto.name || userFromSupabase.user_metadata?.name,
      });

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      // 如果用户没有头像，自动生成一个基于首字母的头像
      const avatarUrl = user.avatar_url || AvatarGenerator.generateAvatarUrl(user.name, user.email);

      logger.info(`用户注册成功: ${registerDto.email}`);

      return {
        ...tokens,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: avatarUrl,
        },
        expiresIn: 3600, // 1小时
      };
    } catch (error) {
      logger.error(`用户注册失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.REGISTRATION_FAILED, error);
    }
  }

  /**
   * 用户登录
   */
  async login(loginDto: LoginDto): Promise<AuthResponseDto> {
    try {
      logger.info(`用户登录: ${loginDto.email}`);

      // 使用 Supabase Auth API 登录
      const authResponse = await this.callSupabaseAuth('/auth/v1/token?grant_type=password', {
        email: loginDto.email,
        password: loginDto.password,
      });

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        logger.error(`❌ Supabase login failed for ${loginDto.email}`);
        logger.error(`Error details: ${JSON.stringify(authResponse)}`);
        throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS);
      }

      // Supabase token API 可能返回 { user: {...} } 或直接返回 user 对象
      const userFromSupabase = authResponse.user || authResponse;

      // 获取用户信息
      const user = await this.getUserFromDatabase(userFromSupabase.id);

      if (!user) {
        throw new ResponseError(ErrorCodes.AUTH.USER_ACCOUNT_NOT_FOUND);
      }

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      // 如果用户没有头像，自动生成一个基于首字母的头像
      const avatarUrl = user.avatar_url || AvatarGenerator.generateAvatarUrl(user.name, user.email);

      logger.info(`用户登录成功: ${loginDto.email}`);

      return {
        ...tokens,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: avatarUrl,
        },
        expiresIn: 3600,
      };
    } catch (error) {
      logger.error(`用户登录失败: ${error.message}`, error.stack);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS, error);
    }
  }

  /**
   * 发送 OTP 验证码
   */
  async sendOtp(otpLoginDto: OtpLoginDto): Promise<OtpResponseDto> {
    try {
      logger.info(`发送OTP验证码: ${otpLoginDto.email}`);

      // 使用 Supabase Auth API 发送 OTP 验证码（不是魔法链接）
      const authResponse = await this.callSupabaseAuth('/auth/v1/otp', {
        email: otpLoginDto.email,
        create_user: true,  // 如果用户不存在则自动创建
        data: {},
      });

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        logger.error(`发送OTP失败: ${JSON.stringify(authResponse)}`);
        throw new ResponseError(ErrorCodes.AUTH.EMAIL_SEND_FAILED);
      }

      logger.info(`OTP验证码发送成功: ${otpLoginDto.email}`);

      return {
        success: true,
        message: '验证码已发送到您的邮箱',
        email: otpLoginDto.email,
      };
    } catch (error) {
      logger.error(`发送OTP失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.EMAIL_SEND_FAILED, error);
    }
  }

  /**
   * 验证 OTP 并登录
   */
  async verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<AuthResponseDto> {
    try {
      logger.info(`验证OTP: ${verifyOtpDto.email}`);

      // 使用 Supabase Auth API 验证 OTP
      const authResponse = await this.callSupabaseAuth('/auth/v1/verify', {
        email: verifyOtpDto.email,
        token: verifyOtpDto.token,
        type: 'email',
      });

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        throw new ResponseError(ErrorCodes.AUTH.OTP_VERIFICATION_FAILED);
      }

      // Supabase verify API 可能返回 { user: {...} } 或直接返回 user 对象
      const userFromSupabase = authResponse.user || authResponse;

      // 创建或获取用户信息
      const user = await this.createOrUpdateUser({
        id: userFromSupabase.id,
        email: userFromSupabase.email,
        name: userFromSupabase.user_metadata?.name,
      });

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      logger.info(`OTP验证成功: ${verifyOtpDto.email}`);

      return {
        ...tokens,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatar_url,
        },
        expiresIn: 3600,
      };
    } catch (error) {
      logger.error(`验证OTP失败: ${error.message}`, error.stack);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.AUTH.OTP_VERIFICATION_FAILED, error);
    }
  }

  /**
   * Google OAuth 登录
   * 使用 Supabase 的 ID Token 验证进行 Google 登录
   */
  async googleOAuthLogin(googleOAuthDto: GoogleOAuthDto): Promise<AuthResponseDto> {
    try {
      logger.info('Google OAuth 登录请求');

      // 使用 Supabase Auth API 验证 Google ID Token
      const authResponse = await this.callSupabaseAuth('/auth/v1/token?grant_type=id_token', {
        provider: 'google',
        id_token: googleOAuthDto.idToken,
        access_token: googleOAuthDto.accessToken,
      });

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        logger.error(`Google OAuth 验证失败: ${JSON.stringify(authResponse)}`);
        throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS);
      }

      // Supabase token API 可能返回 { user: {...} } 或直接返回 user 对象
      const userFromSupabase = authResponse.user || authResponse;

      // 创建或更新用户信息
      const user = await this.createOrUpdateUser({
        id: userFromSupabase.id,
        email: userFromSupabase.email,
        name: userFromSupabase.user_metadata?.name || userFromSupabase.user_metadata?.full_name,
        avatarUrl: userFromSupabase.user_metadata?.avatar_url || userFromSupabase.user_metadata?.picture,
      });

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      logger.info(`Google OAuth 登录成功: ${user.email}`);

      return {
        ...tokens,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatar_url,
        },
        expiresIn: 3600,
      };
    } catch (error) {
      logger.error(`Google OAuth 登录失败: ${error.message}`, error.stack);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS, error);
    }
  }

  /**
   * 刷新 Token
   */
  async refreshToken(refreshToken: string): Promise<Pick<AuthResponseDto, 'accessToken' | 'refreshToken' | 'expiresIn'>> {
    try {
      logger.info('刷新Token');

      // 验证 refresh token
      const payload = this.jwtService.verify(refreshToken);
      const userId = payload.userId;

      // 检查用户是否存在
      const user = await this.getUserFromDatabase(userId);
      if (!user) {
        throw new ResponseError(ErrorCodes.AUTH.USER_ACCOUNT_NOT_FOUND);
      }

      // 生成新的 tokens
      const tokens = this.generateTokens({ userId });

      logger.info('Token刷新成功');

      return {
        ...tokens,
        expiresIn: 3600,
      };
    } catch (error) {
      logger.error(`刷新Token失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.REFRESH_TOKEN_INVALID, error);
    }
  }

  /**
   * 获取当前用户信息
   */
  async getCurrentUser(userId: string): Promise<UserResponseDto> {
    try {
      const user = await this.getUserFromDatabase(userId);
      if (!user) {
        throw new ResponseError(ErrorCodes.AUTH.USER_ACCOUNT_NOT_FOUND);
      }

      // 如果用户没有头像，自动生成一个基于首字母的头像
      const avatarUrl = user.avatar_url || AvatarGenerator.generateAvatarUrl(user.name, user.email);

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: avatarUrl,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
      };
    } catch (error) {
      logger.error(`获取用户信息失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.USER_INFO_FETCH_FAILED, error);
    }
  }

  /**
   * 生成 JWT tokens
   */
  private generateTokens(payload: { userId: string }) {
    return {
      accessToken: this.jwtService.sign(payload, { expiresIn: '1h' }),
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }),
    };
  }

  /**
   * 调用 Supabase Auth API
   */
  private async callSupabaseAuth(endpoint: string, data: any) {
    const url = `${this.supabaseUrl}${endpoint}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': this.supabaseAnonKey,
      },
      body: JSON.stringify(data),
    });

    const jsonResponse = await response.json();

    // 添加详细日志
    logger.info(`Supabase API call to ${endpoint}`);
    logger.info(`HTTP Status: ${response.status}`);
    logger.info(`Response: ${JSON.stringify(jsonResponse)}`);

    return jsonResponse;
  }

  /**
   * 创建或更新用户到我们的数据库
   */
  private async createOrUpdateUser(userData: { id: string; email: string; name?: string; avatarUrl?: string }) {
    try {
      // 先尝试获取用户
      const existingUser = await this.supabaseApi.getById('users', userData.id);

      if (existingUser) {
        // 更新用户信息
        return await this.supabaseApi.patch('users', userData.id, {
          email: userData.email,
          name: userData.name || existingUser.name,
          avatar_url: userData.avatarUrl || existingUser.avatar_url,
          updated_at: new Date().toISOString(),
        });
      } else {
        // 创建新用户
        return await this.supabaseApi.post('users', {
          id: userData.id,
          email: userData.email,
          name: userData.name || '',
          avatar_url: userData.avatarUrl || null,
          total_workouts: 0,
          total_duration_sec: 0,
          current_streak: 0,
          longest_streak: 0,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
      }
    } catch (error) {
      logger.error(`创建或更新用户失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.USER_DATA_PROCESSING_FAILED, error);
    }
  }

  /**
   * 从数据库获取用户
   */
  private async getUserFromDatabase(userId: string) {
    try {
      return await this.supabaseApi.getById('users', userId);
    } catch (error) {
      logger.error(`获取用户失败: ${error.message}`, error.stack);
      return null;
    }
  }
}

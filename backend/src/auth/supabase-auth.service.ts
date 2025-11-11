import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { RegisterDto, LoginDto, OtpLoginDto, VerifyOtpDto } from './dto/auth.dto';
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

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
        throw new ResponseError(ErrorCodes.AUTH.REGISTRATION_FAILED);
      }

      // 创建或更新用户记录到我们的数据库
      const user = await this.createOrUpdateUser({
        id: authResponse.user.id,
        email: authResponse.user.email,
        name: registerDto.name || authResponse.user.user_metadata?.name,
      });

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      logger.info(`用户注册成功: ${registerDto.email}`);

      return {
        ...tokens,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatar_url,
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
        throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS);
      }

      // 获取用户信息
      const user = await this.getUserFromDatabase(authResponse.user.id);

      if (!user) {
        throw new ResponseError(ErrorCodes.AUTH.USER_ACCOUNT_NOT_FOUND);
      }

      // 生成我们自己的 JWT token
      const tokens = this.generateTokens({ userId: user.id });

      logger.info(`用户登录成功: ${loginDto.email}`);

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

      // 使用 Supabase Auth API 发送 OTP
      const authResponse = await this.callSupabaseAuth('/auth/v1/otp', {
        email: otpLoginDto.email,
      });

      if (authResponse.error_code || authResponse.error || authResponse.msg) {
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

      // 创建或获取用户信息
      const user = await this.createOrUpdateUser({
        id: authResponse.user.id,
        email: authResponse.user.email,
        name: authResponse.user.user_metadata?.name,
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

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatar_url,
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

    return await response.json();
  }

  /**
   * 创建或更新用户到我们的数据库
   */
  private async createOrUpdateUser(userData: { id: string; email: string; name?: string }) {
    try {
      // 先尝试获取用户
      const existingUser = await this.supabaseApi.getById('users', userData.id);

      if (existingUser) {
        // 更新用户信息
        return await this.supabaseApi.patch('users', userData.id, {
          email: userData.email,
          name: userData.name || existingUser.name,
          updated_at: new Date().toISOString(),
        });
      } else {
        // 创建新用户
        return await this.supabaseApi.post('users', {
          id: userData.id,
          email: userData.email,
          name: userData.name || '',
          avatar_url: null,
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
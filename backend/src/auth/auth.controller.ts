import {
  Controller,
  Post,
  Get,
  Body,
  HttpStatus,
  Logger,
  UseGuards,
  Request,
  ValidationPipe,
  UsePipes,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { SupabaseAuthService } from './supabase-auth.service';
import {
  RegisterDto,
  LoginDto,
  OtpLoginDto,
  VerifyOtpDto,
  RefreshTokenDto,
  GoogleOAuthDto,
} from './dto/auth.dto';
import {
  AuthResponseDto,
  OtpResponseDto,
  UserResponseDto,
} from './dto/auth-response.dto';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { logger } from '../common/logger/logger';


/**
 * Auth Controller 类
 * 提供用户认证相关的 REST API 接口
 * 支持邮箱密码登录和 OTP 邮箱验证登录
 */
@ApiTags('Authentication')
@Controller('rest/v1/auth')
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class AuthController {
  // private readonly logger = new Logger(AuthController.name);

  constructor(private readonly supabaseAuthService: SupabaseAuthService) {
    logger.info('AuthController initialized with SupabaseAuthService');
  }

  /**
   * 用户注册
   */
  @Post('register')
  @ApiOperation({
    summary: '用户注册',
    description: '使用邮箱和密码注册新用户账号',
  })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '注册成功',
    type: AuthResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '注册失败 - 参数错误或邮箱已存在',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async register(@Body() registerDto: RegisterDto): Promise<AuthResponseDto> {
    try {
      logger.info(`用户注册请求: ${registerDto.email}`);
      const result = await this.supabaseAuthService.register(registerDto);
      logger.info(`用户注册成功: ${registerDto.email}`);
      return result;
    } catch (error) {
      logger.error(`用户注册失败: ${registerDto.email}`, error.stack);
      throw error;
    }
  }

  /**
   * 用户登录
   */
  @Post('login')
  @ApiOperation({
    summary: '用户登录',
    description: '使用邮箱和密码登录用户账号',
  })
  @ApiBody({ type: LoginDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '登录成功',
    type: AuthResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: '登录失败 - 邮箱或密码错误',
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async login(@Body() loginDto: LoginDto): Promise<AuthResponseDto> {
    try {
      logger.info(`用户登录请求: ${loginDto.email}`);
      const result = await this.supabaseAuthService.login(loginDto);
      logger.info(`用户登录成功: ${loginDto.email}`);
      return result;
    } catch (error) {
      logger.error(`用户登录失败: ${loginDto.email}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.SUPABASE_LOGIN_FAILED, error, { email: loginDto.email });
    }
  }

  /**
   * 发送 OTP 验证码
   */
  @Post('otp/send')
  @ApiOperation({
    summary: '发送 OTP 验证码',
    description: '向指定邮箱发送一次性验证码，用于无密码登录',
  })
  @ApiBody({ type: OtpLoginDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '验证码发送成功',
    type: OtpResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '发送失败 - 邮箱格式错误或其他问题',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async sendOtp(@Body() otpLoginDto: OtpLoginDto): Promise<OtpResponseDto> {
    try {
      logger.info(`发送OTP请求: ${otpLoginDto.email}`);
      const result = await this.supabaseAuthService.sendOtp(otpLoginDto);
      logger.info(`OTP发送成功: ${otpLoginDto.email}`);
      return result;
    } catch (error) {
      logger.error(`发送OTP失败: ${otpLoginDto.email}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.SUPABASE_SEND_OTP_FAILED, error, { email: otpLoginDto.email });

    }
  }

  /**
   * 验证 OTP 并登录
   */
  @Post('otp/verify')
  @ApiOperation({
    summary: '验证 OTP 并登录',
    description: '使用邮箱和 OTP 验证码登录用户账号',
  })
  @ApiBody({ type: VerifyOtpDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '验证成功，登录完成',
    type: AuthResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: '验证失败 - 验证码错误或已过期',
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto): Promise<AuthResponseDto> {
    try {
      logger.info(`验证OTP请求: ${verifyOtpDto.email}`);
      const result = await this.supabaseAuthService.verifyOtp(verifyOtpDto);
      logger.info(`OTP验证成功: ${verifyOtpDto.email}`);
      return result;
    } catch (error) {
      logger.error(`验证OTP失败: ${verifyOtpDto.email}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.OTP_VERIFICATION_FAILED, error, { email: verifyOtpDto.email });
    }
  }

  /**
   * Google OAuth 登录
   */
  @Post('google')
  @ApiOperation({
    summary: 'Google OAuth 登录',
    description: '使用 Google ID Token 进行用户认证和登录',
  })
  @ApiBody({ type: GoogleOAuthDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Google 登录成功',
    type: AuthResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'Google Token 验证失败',
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '请求参数错误',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async googleOAuthLogin(@Body() googleOAuthDto: GoogleOAuthDto): Promise<AuthResponseDto> {
    try {
      logger.info('Google OAuth 登录请求');
      const result = await this.supabaseAuthService.googleOAuthLogin(googleOAuthDto);
      logger.info('Google OAuth 登录成功');
      return result;
    } catch (error) {
      logger.error('Google OAuth 登录失败', error.stack);
      throw new ResponseError(ErrorCodes.AUTH.INVALID_CREDENTIALS, error);
    }
  }

  /**
   * 刷新 Token
   */
  @Post('refresh')
  @ApiOperation({
    summary: '刷新 Access Token',
    description: '使用 Refresh Token 获取新的 Access Token',
  })
  @ApiBody({ type: RefreshTokenDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Token 刷新成功',
    schema: {
      type: 'object',
      properties: {
        accessToken: {
          type: 'string',
          description: '新的 Access Token',
          example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        },
        refreshToken: {
          type: 'string',
          description: '新的 Refresh Token',
          example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        },
        expiresIn: {
          type: 'number',
          description: 'Token 过期时间（秒）',
          example: 3600,
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'Refresh Token 无效或已过期',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async refreshToken(@Body() refreshTokenDto: RefreshTokenDto) {
    try {
      logger.info('Token刷新请求');
      const result = await this.supabaseAuthService.refreshToken(refreshTokenDto.refreshToken);
      logger.info('Token刷新成功');
      return result;
    } catch (error) {
      logger.error('Token刷新失败', error.stack);
      throw new ResponseError(ErrorCodes.AUTH.REFRESH_TOKEN_INVALID, error, { token: refreshTokenDto.refreshToken });
    }
  }

  /**
   * 获取当前用户信息
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: '获取当前用户信息',
    description: '获取当前登录用户的详细信息',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '获取成功',
    type: UserResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: '未登录或 Token 无效',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: '服务器内部错误',
  })
  async getCurrentUser(@Request() req): Promise<UserResponseDto> {
    try {
      const userId = req.user.userId;
      logger.info(`获取用户信息请求: ${userId}`);
      const result = await this.supabaseAuthService.getCurrentUser(userId);
      logger.info(`获取用户信息成功: ${userId}`);
      return result;
    } catch (error) {
      logger.error(`获取用户信息失败: ${req.user?.userId}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.GET_USER_INFO_FAILED, error, { userId: req.user?.userId });
    }
  }

  /**
   * 登出（客户端处理）
   */
  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: '用户登出',
    description: '用户登出（主要由客户端删除 Token 实现）',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '登出成功',
    schema: {
      type: 'object',
      properties: {
        message: {
          type: 'string',
          example: '登出成功',
        },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: '未登录或 Token 无效',
  })
  async logout(@Request() req) {
    try {
      const userId = req.user.userId;
      logger.info(`用户登出请求: ${userId}`);

      // JWT 是无状态的，服务端不需要特殊处理
      // 客户端应该删除存储的 token

      logger.info(`用户登出成功: ${userId}`);
      return {
        message: '登出成功',
      };
    } catch (error) {
      logger.error(`用户登出失败: ${req.user?.userId}`, error.stack);
      throw new ResponseError(ErrorCodes.AUTH.LOGOUT_FAILED, error, { userId: req.user?.userId });
    }
  }
}
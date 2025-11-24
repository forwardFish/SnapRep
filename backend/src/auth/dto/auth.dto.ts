import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, MinLength, IsOptional, IsString } from 'class-validator';

/**
 * 用户注册 DTO
 */
export class RegisterDto {
  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: '密码（至少8位）',
    example: 'password123',
    minLength: 8,
  })
  @IsNotEmpty()
  @MinLength(8)
  password: string;

  @ApiProperty({
    description: '用户名（可选）',
    example: '张三',
    required: false,
  })
  @IsOptional()
  @IsString()
  name?: string;
}

/**
 * 用户登录 DTO
 */
export class LoginDto {
  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: '密码',
    example: 'password123',
  })
  @IsNotEmpty()
  password: string;
}

/**
 * OTP 登录请求 DTO
 */
export class OtpLoginDto {
  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  @IsEmail()
  email: string;
}

/**
 * OTP 验证 DTO
 */
export class VerifyOtpDto {
  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: 'OTP 验证码',
    example: '123456',
  })
  @IsNotEmpty()
  @IsString()
  token: string;
}

/**
 * 刷新Token DTO
 */
export class RefreshTokenDto {
  @ApiProperty({
    description: 'Refresh Token',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}

/**
 * Google OAuth 登录 DTO
 */
export class GoogleOAuthDto {
  @ApiProperty({
    description: 'Google ID Token',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFiZj...',
  })
  @IsNotEmpty()
  @IsString()
  idToken: string;

  @ApiProperty({
    description: 'Google Access Token (可选)',
    example: 'ya29.a0AfH6SMBx...',
    required: false,
  })
  @IsOptional()
  @IsString()
  accessToken?: string;
}
import { ApiProperty } from '@nestjs/swagger';

/**
 * 认证响应 DTO
 */
export class AuthResponseDto {
  @ApiProperty({
    description: 'Access Token',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  accessToken: string;

  @ApiProperty({
    description: 'Refresh Token',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  refreshToken: string;

  @ApiProperty({
    description: '用户信息',
    type: 'object',
  })
  user: {
    id: string;
    email: string;
    name?: string;
    avatarUrl?: string;
  };

  @ApiProperty({
    description: 'Token 过期时间（秒）',
    example: 3600,
  })
  expiresIn: number;
}

/**
 * OTP 发送响应 DTO
 */
export class OtpResponseDto {
  @ApiProperty({
    description: '是否发送成功',
    example: true,
  })
  success: boolean;

  @ApiProperty({
    description: '消息',
    example: '验证码已发送到您的邮箱',
  })
  message: string;

  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  email: string;
}

/**
 * 用户信息响应 DTO
 */
export class UserResponseDto {
  @ApiProperty({
    description: '用户ID',
    example: 'cm3y5x1w2000xxx',
  })
  id: string;

  @ApiProperty({
    description: '邮箱地址',
    example: 'user@example.com',
  })
  email: string;

  @ApiProperty({
    description: '用户名',
    example: '张三',
    required: false,
  })
  name?: string;

  @ApiProperty({
    description: '头像URL',
    example: 'https://example.com/avatar.jpg',
    required: false,
  })
  avatarUrl?: string;

  @ApiProperty({
    description: '创建时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  createdAt: string;

  @ApiProperty({
    description: '更新时间',
    example: '2024-01-01T00:00:00.000Z',
  })
  updatedAt: string;
}
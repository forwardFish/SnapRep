// 用户类型定义，基于Prisma User模型
export interface UserInfo {
  id: string; // Supabase Auth UUID
  email?: string | null;
  password?: string | null;
  name?: string | null;
  avatarUrl?: string | null;
  totalWorkouts?: number;
  totalDurationSec?: number;
  currentStreak?: number;
  longestStreak?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

// 简化的用户实体类（用于JWT认证）
export class UserEntity implements UserInfo {
  id: string;
  email?: string | null;
  password?: string | null;
  name?: string | null;
  avatarUrl?: string | null;
  totalWorkouts?: number;
  totalDurationSec?: number;
  currentStreak?: number;
  longestStreak?: number;
  createdAt?: Date;
  updatedAt?: Date;

  constructor(partial: Partial<UserInfo> = {}) {
    Object.assign(this, partial);
  }
}
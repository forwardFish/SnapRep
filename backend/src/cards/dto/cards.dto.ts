import {
    IsString,
    IsOptional,
    IsBoolean,
    IsArray,
    IsNumber,
    Min,
    Max,
    IsEnum,
    IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RarityLevel } from '../../common/types/prisma-enums';
import { IsSessionId } from '../../common/validators/session-id.validator';

/**
 * 生成分享卡片请求 DTO
 */
export class GenerateCardDto {
    @ApiProperty({
        description: '训练会话ID',
        example: 'cuid_session_123',
    })
    @IsString()
    @IsSessionId()
    sessionId: string;

    @ApiPropertyOptional({
        description: '卡片模板',
        example: 'classic',
        enum: ['classic', 'minimal', 'vibrant', 'dark', 'gradient'],
    })
    @IsOptional()
    @IsString()
    cardTemplate?: string = 'classic';

    @ApiPropertyOptional({
        description: '自定义分享文案',
        example: '今天完成了3个动作，感觉超棒！💪',
        maxLength: 500,
    })
    @IsOptional()
    @IsString()
    shareText?: string;

    @ApiPropertyOptional({
        description: '是否公开分享',
        example: true,
    })
    @IsOptional()
    @IsBoolean()
    isPublic?: boolean = true;

    @ApiPropertyOptional({
        description: '特殊标签',
        example: ['first_workout', 'streak_milestone', 'equipment_master'],
        isArray: true,
    })
    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    specialTags?: string[] = [];

    @ApiPropertyOptional({
        description: '城市版本标识',
        example: 'beijing_2024',
    })
    @IsOptional()
    @IsString()
    cityEdition?: string;

    @ApiPropertyOptional({
        description: '主题周标识',
        example: 'chair_week_2024_01',
    })
    @IsOptional()
    @IsString()
    themeWeek?: string;

    @ApiPropertyOptional({
        description: '是否强制重新生成',
        example: false,
    })
    @IsOptional()
    @IsBoolean()
    forceRegenerate?: boolean = false;
}

/**
 * 更新分享卡片 DTO
 */
export class UpdateCardDto {
    @ApiPropertyOptional({
        description: '自定义分享文案',
        maxLength: 500,
    })
    @IsOptional()
    @IsString()
    shareText?: string;

    @ApiPropertyOptional({
        description: '是否公开分享',
    })
    @IsOptional()
    @IsBoolean()
    isPublic?: boolean;

    @ApiPropertyOptional({
        description: '特殊标签',
        isArray: true,
    })
    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    specialTags?: string[];

    @ApiPropertyOptional({
        description: '卡片模板',
    })
    @IsOptional()
    @IsString()
    cardTemplate?: string;
}

/**
 * 卡片查询 DTO
 */
export class CardsQueryDto {
    @ApiPropertyOptional({
        description: '基础稀有度等级筛选',
        enum: RarityLevel,
    })
    @IsOptional()
    @IsEnum(RarityLevel)
    rarity?: RarityLevel;

    @ApiPropertyOptional({
        description: '个人星级筛选 (1-5星)',
        example: 5,
        minimum: 1,
        maximum: 5,
    })
    @IsOptional()
    @IsNumber()
    @Min(1)
    @Max(5)
    personalStars?: number;

    @ApiPropertyOptional({
        description: '器材系列筛选',
        example: 'chair',
    })
    @IsOptional()
    @IsString()
    equipmentSeries?: string;

    @ApiPropertyOptional({
        description: '主题周筛选',
        example: 'chair_week_2024_01',
    })
    @IsOptional()
    @IsString()
    themeWeek?: string;

    @ApiPropertyOptional({
        description: '开始日期',
        example: '2024-01-01',
    })
    @IsOptional()
    @IsString()
    fromDate?: string;

    @ApiPropertyOptional({
        description: '结束日期',
        example: '2024-01-31',
    })
    @IsOptional()
    @IsString()
    toDate?: string;

    @ApiPropertyOptional({
        description: '是否只显示公开卡片',
        example: true,
    })
    @IsOptional()
    @IsBoolean()
    publicOnly?: boolean;

    @ApiPropertyOptional({
        description: '返回数量限制',
        example: 20,
        minimum: 1,
        maximum: 100,
    })
    @IsOptional()
    @Type(() => Number)
    @IsNumber()
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        description: '偏移量',
        example: 0,
        minimum: 0,
    })
    @IsOptional()
    @Type(() => Number)
    @IsNumber()
    @Min(0)
    offset?: number = 0;
}

/**
 * 稀有度计算请求 DTO
 */
export class CalculateRarityDto {
    @ApiProperty({
        description: '器材代码',
        example: 'chair',
    })
    @IsString()
    equipmentCode: string;

    @ApiPropertyOptional({
        description: '地区代码',
        example: 'CN_Beijing',
    })
    @IsOptional()
    @IsString()
    region?: string;

    @ApiPropertyOptional({
        description: '是否强制重新计算',
        example: false,
    })
    @IsOptional()
    @IsBoolean()
    forceRecalculate?: boolean = false;
}

/**
 * 卡片分享统计 DTO
 */
export class CardShareStatsDto {
    @ApiProperty({
        description: '分享卡片ID',
        example: 'cuid_card_123',
    })
    @IsString()
    cardId: string;

    @ApiPropertyOptional({
        description: '分享平台',
        example: 'wechat',
        enum: [
            'wechat',
            'weibo',
            'douyin',
            'xiaohongshu',
            'twitter',
            'instagram',
            'facebook',
            'other',
        ],
    })
    @IsOptional()
    @IsString()
    platform?: string = 'other';

    @ApiPropertyOptional({
        description: '来源页面',
        example: 'workout_result',
    })
    @IsOptional()
    @IsString()
    source?: string;
}

/**
 * 批量获取稀有度 DTO
 */
export class BatchRarityDto {
    @ApiProperty({
        description: '器材代码列表',
        example: ['chair', 'wall', 'bottle', 'none'],
        isArray: true,
    })
    @IsArray()
    @IsString({ each: true })
    equipmentCodes: string[];

    @ApiPropertyOptional({
        description: '地区代码',
        example: 'CN_Beijing',
    })
    @IsOptional()
    @IsString()
    region?: string;
}

/**
 * 收藏统计查询 DTO
 */
export class CollectionStatsDto {
    @ApiPropertyOptional({
        description: '统计维度',
        example: 'rarity',
        enum: ['rarity', 'equipment', 'theme_week', 'monthly'],
    })
    @IsOptional()
    @IsString()
    dimension?: string = 'rarity';

    @ApiPropertyOptional({
        description: '统计时间范围（天）',
        example: 365,
        minimum: 1,
        maximum: 1000,
    })
    @IsOptional()
    @IsNumber()
    @Min(1)
    @Max(1000)
    days?: number = 365;
}

/**
 * 个人星级计算 DTO (v3.0 新增)
 */
export class PersonalStarsDto {
    @ApiProperty({
        description: '器材代码',
        example: 'chair',
    })
    @IsString()
    equipmentCode: string;

    @ApiProperty({
        description: '用户ID',
        example: 'user_uuid_123',
    })
    @IsString()
    @IsUUID()
    userId: string;
}

/**
 * 批量个人星级计算 DTO (v3.0 新增)
 */
export class BatchPersonalStarsDto {
    @ApiProperty({
        description: '器材代码列表',
        example: ['chair', 'wall', 'bottle', 'none'],
        isArray: true,
    })
    @IsArray()
    @IsString({ each: true })
    equipmentCodes: string[];

    @ApiProperty({
        description: '用户ID',
        example: 'user_uuid_123',
    })
    @IsString()
    @IsUUID()
    userId: string;
}

import {
  Controller,
  Get,
  Post,
  Patch,
  Query,
  Param,
  Body,
  HttpStatus,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
} from '@nestjs/swagger';
import { ChallengesService } from './challenges.service';
import { GetChallengesQueryDto } from './dto/get-challenges-query.dto';
import {
  GetChallengesResponseDto,
  ChallengeItemDto,
  ChallengeCompletionDto,
} from './dto/get-challenges-response.dto';
import { ConfigService } from '@nestjs/config';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';

@ApiTags('challenges')
@Controller('rest/v1/challenges')
export class ChallengesController {
  constructor(
    private readonly challengesService: ChallengesService,
    private readonly configService: ConfigService,
    private readonly supabaseApi: SupabaseApiService,
  ) {}

  /**
   * Get challenge items list
   * Purpose: Display challenge items in a 3x4 grid (12 items total)
   */
  @Get()
  @ApiOperation({ summary: 'Get challenge items list' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Successfully retrieved challenge items',
    type: GetChallengesResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid request parameters',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: 'Internal server error',
  })
  async findAll(
    @Query() queryDto: GetChallengesQueryDto,
  ): Promise<GetChallengesResponseDto> {
    try {
      logger.info('Fetching challenge items using SupabaseApiService');

      const filter: any = {};
      if (queryDto.isActive !== undefined) {
        filter.is_active = queryDto.isActive;
      }

      const challenges = await this.supabaseApi.get(
        'challenge_items',
        filter,
        { orderBy: 'display_order.asc,total_participants.desc' }
      );

      const { page = 1, pageSize = 12 } = queryDto;
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedData = challenges.slice(startIndex, endIndex);

      return {
        data: paginatedData.map((item: any) => ({
          id: item.id,
          code: item.code,
          name: item.name,
          emoji: item.emoji,
          difficulty: item.difficulty,
          baseRarity: item.base_rarity,
          exerciseCount: item.exercise_count,
          estimatedMinutes: item.estimated_minutes,
          description: item.description,
          totalParticipants: item.total_participants,
          totalCompletions: item.total_completions,
          completionRate: item.completion_rate,
          isPopular: item.is_popular,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
        })),
        pagination: {
          total: challenges.length,
          page,
          pageSize,
          totalPages: Math.ceil(challenges.length / pageSize),
          hasNextPage: endIndex < challenges.length,
          hasPreviousPage: page > 1,
        },
      };
    } catch (error) {
      logger.error('Failed to fetch challenge items:', error);
      throw new InternalServerErrorException('Failed to fetch challenge items');
    }
  }

  /**
   * Get single challenge item by ID
   */
  @Get(':id')
  @ApiOperation({
    summary: 'Get challenge item details',
    description: 'Get detailed information for a specific challenge item',
  })
  @ApiParam({
    name: 'id',
    description: 'Challenge item ID',
    example: 'clxxx...',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Successfully retrieved challenge item',
    type: ChallengeItemDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Challenge item not found',
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: 'Internal server error',
  })
  async findOne(@Param('id') id: string): Promise<ChallengeItemDto> {
    try {
      logger.info(`Fetching challenge item: id=${id}`);

      const item = await this.supabaseApi.getById('challenge_items', id);
      if (!item) {
        throw new NotFoundException(`Challenge item with ID ${id} not found`);
      }

      return {
        id: item.id,
        code: item.code,
        name: item.name,
        emoji: item.emoji,
        difficulty: item.difficulty,
        baseRarity: item.base_rarity,
        exerciseCount: item.exercise_count,
        estimatedMinutes: item.estimated_minutes,
        description: item.description,
        totalParticipants: item.total_participants,
        totalCompletions: item.total_completions,
        completionRate: item.completion_rate,
        isPopular: item.is_popular,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      };
    } catch (error) {
      logger.error(`Failed to fetch challenge item ${id}:`, error);
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to fetch challenge item');
    }
  }

  /**
   * Get challenge item by code
   */
  @Get('code/:code')
  @ApiOperation({
    summary: 'Get challenge item by code',
    description: 'Get challenge item using its unique code',
  })
  @ApiParam({
    name: 'code',
    description: 'Challenge item code',
    example: 'umbrella',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Successfully retrieved challenge item',
    type: ChallengeItemDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Challenge item not found',
  })
  async findByCode(@Param('code') code: string): Promise<ChallengeItemDto> {
    try {
      logger.info(`Fetching challenge item by code: ${code}`);

      const item = await this.supabaseApi.getByField('challenge_items', 'code', code);
      if (!item) {
        throw new NotFoundException(`Challenge item with code ${code} not found`);
      }

      return {
        id: item.id,
        code: item.code,
        name: item.name,
        emoji: item.emoji,
        difficulty: item.difficulty,
        baseRarity: item.base_rarity,
        exerciseCount: item.exercise_count,
        estimatedMinutes: item.estimated_minutes,
        description: item.description,
        totalParticipants: item.total_participants,
        totalCompletions: item.total_completions,
        completionRate: item.completion_rate,
        isPopular: item.is_popular,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      };
    } catch (error) {
      logger.error(`Failed to fetch challenge item by code ${code}:`, error);
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to fetch challenge item');
    }
  }

  /**
   * Get user's challenge completions
   */
  @Get('completions/user/:userId')
  @ApiOperation({
    summary: 'Get user challenge completions',
    description: 'Get all challenge completions for a specific user',
  })
  @ApiParam({
    name: 'userId',
    description: 'User ID',
    example: 'clxxx...',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Successfully retrieved user completions',
    type: [ChallengeCompletionDto],
  })
  async getUserCompletions(
    @Param('userId') userId: string,
  ): Promise<ChallengeCompletionDto[]> {
    try {
      logger.info(`Fetching challenge completions for user: ${userId}`);

      const completions = await this.supabaseApi.get(
        'challenge_completions',
        { user_id: userId },
        { orderBy: 'completed_at.desc' }
      );

      return completions.map((comp: any) => ({
        id: comp.id,
        userId: comp.user_id,
        challengeItemId: comp.challenge_item_id,
        status: comp.status,
        startedAt: comp.started_at,
        completedAt: comp.completed_at,
        actualDuration: comp.actual_duration,
        completedCount: comp.completed_count,
        difficultyFelt: comp.difficulty_felt,
        enjoymentRating: comp.enjoyment_rating,
        badgeEarned: comp.badge_earned,
        badgeAwarded: comp.badge_awarded,
        xpEarned: comp.xp_earned,
        createdAt: comp.created_at,
        updatedAt: comp.updated_at,
      }));
    } catch (error) {
      logger.error(`Failed to fetch user completions for ${userId}:`, error);
      throw new InternalServerErrorException('Failed to fetch user completions');
    }
  }

  /**
   * Start a challenge
   */
  @Post('completions/start')
  @ApiOperation({
    summary: 'Start a challenge',
    description: 'Create a new challenge completion record when user starts a challenge',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Challenge started successfully',
    type: ChallengeCompletionDto,
  })
  async startChallenge(
    @Body() body: { userId: string; challengeItemId: string },
  ): Promise<ChallengeCompletionDto> {
    try {
      logger.info(`Starting challenge: userId=${body.userId}, challengeItemId=${body.challengeItemId}`);

      // Create completion record
      const completion = await this.supabaseApi.create('challenge_completions', {
        user_id: body.userId,
        challenge_item_id: body.challengeItemId,
        status: 'STARTED',
        started_at: new Date().toISOString(),
      });

      // Increment participant count
      const challenge = await this.supabaseApi.getById('challenge_items', body.challengeItemId);
      if (challenge) {
        await this.supabaseApi.update('challenge_items', body.challengeItemId, {
          total_participants: challenge.total_participants + 1,
        });
      }

      return {
        id: completion.id,
        userId: completion.user_id,
        challengeItemId: completion.challenge_item_id,
        status: completion.status,
        startedAt: completion.started_at,
        completedAt: completion.completed_at,
        actualDuration: completion.actual_duration,
        completedCount: completion.completed_count,
        difficultyFelt: completion.difficulty_felt,
        enjoymentRating: completion.enjoyment_rating,
        badgeEarned: completion.badge_earned,
        badgeAwarded: completion.badge_awarded,
        xpEarned: completion.xp_earned,
        createdAt: completion.created_at,
        updatedAt: completion.updated_at,
      };
    } catch (error) {
      logger.error('Failed to start challenge:', error);
      throw new InternalServerErrorException('Failed to start challenge');
    }
  }

  /**
   * Complete a challenge
   */
  @Patch('completions/:id/complete')
  @ApiOperation({
    summary: 'Complete a challenge',
    description: 'Mark a challenge as completed and award badge',
  })
  @ApiParam({
    name: 'id',
    description: 'Challenge completion ID',
    example: 'clxxx...',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Challenge completed successfully',
    type: ChallengeCompletionDto,
  })
  async completeChallenge(
    @Param('id') id: string,
    @Body() body: {
      actualDuration?: number;
      completedCount: number;
      difficultyFelt?: number;
      enjoymentRating?: number;
    },
  ): Promise<ChallengeCompletionDto> {
    try {
      logger.info(`Completing challenge: id=${id}`);

      const completion = await this.supabaseApi.getById('challenge_completions', id);
      if (!completion) {
        throw new NotFoundException('Challenge completion not found');
      }

      // Calculate badge based on participant count and rarity
      const challenge = await this.supabaseApi.getById('challenge_items', completion.challenge_item_id);
      let badgeEarned = challenge?.base_rarity || 'COMMON';

      // Update completion record
      const updated = await this.supabaseApi.update('challenge_completions', id, {
        status: 'COMPLETED',
        completed_at: new Date().toISOString(),
        actual_duration: body.actualDuration,
        completed_count: body.completedCount,
        difficulty_felt: body.difficultyFelt,
        enjoyment_rating: body.enjoymentRating,
        badge_earned: badgeEarned,
        badge_awarded: true,
        xp_earned: 100, // Base XP
      });

      // Increment completion count
      if (challenge) {
        const newCompletions = challenge.total_completions + 1;
        const completionRate = newCompletions / challenge.total_participants;
        await this.supabaseApi.update('challenge_items', challenge.id, {
          total_completions: newCompletions,
          completion_rate: completionRate,
        });
      }

      return {
        id: updated.id,
        userId: updated.user_id,
        challengeItemId: updated.challenge_item_id,
        status: updated.status,
        startedAt: updated.started_at,
        completedAt: updated.completed_at,
        actualDuration: updated.actual_duration,
        completedCount: updated.completed_count,
        difficultyFelt: updated.difficulty_felt,
        enjoymentRating: updated.enjoyment_rating,
        badgeEarned: updated.badge_earned,
        badgeAwarded: updated.badge_awarded,
        xpEarned: updated.xp_earned,
        createdAt: updated.created_at,
        updatedAt: updated.updated_at,
      };
    } catch (error) {
      logger.error('Failed to complete challenge:', error);
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to complete challenge');
    }
  }

  /**
   * Get challenge statistics
   */
  @Get('stats/count')
  @ApiOperation({
    summary: 'Get active challenges count',
    description: 'Returns the total number of active challenges',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Successfully retrieved statistics',
    schema: {
      type: 'object',
      properties: {
        count: {
          type: 'number',
          description: 'Number of active challenges',
          example: 12,
        },
      },
    },
  })
  async getActiveCount(): Promise<{ count: number }> {
    try {
      logger.info('Fetching active challenges count');
      const challenges = await this.supabaseApi.get(
        'challenge_items',
        { is_active: true },
        { orderBy: 'created_at.asc' }
      );
      return { count: challenges.length };
    } catch (error) {
      logger.error('Failed to get active challenges count:', error);
      throw new InternalServerErrorException('Failed to get challenges count');
    }
  }
}

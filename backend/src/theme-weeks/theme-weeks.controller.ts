import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Logger,
  UseGuards,
  Request,
  BadRequestException
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ThemeWeeksService } from './theme-weeks.service';
import {
  CurrentThemeWeekDto,
  JoinThemeWeekDto,
  JoinThemeWeekResponseDto,
} from './dto/theme-week.dto';

@ApiTags('Theme Weeks')
@Controller('/api/v1/theme-weeks')
export class ThemeWeeksController {
  private readonly logger = new Logger(ThemeWeeksController.name);

  constructor(private readonly themeWeeksService: ThemeWeeksService) {
    this.logger.log('ThemeWeeksController initialized');
  }

  @Get('current')
  @ApiOperation({
    summary: '获取当前主题周',
    description: '获取当前活跃的主题周信息，包含用户参与状态（如果提供了用户ID）'
  })
  @ApiQuery({
    name: 'userId',
    required: false,
    description: '用户ID，用于获取用户参与状态'
  })
  @ApiResponse({
    status: 200,
    description: '成功获取当前主题周信息',
    type: CurrentThemeWeekDto
  })
  async getCurrentThemeWeek(
    @Query('userId') userId?: string,
  ): Promise<CurrentThemeWeekDto> {
    try {
      this.logger.debug(`Getting current theme week${userId ? ` for user ${userId}` : ''}`);

      const result = await this.themeWeeksService.getCurrentThemeWeek(userId);

      this.logger.debug('Current theme week retrieved successfully');
      return result;
    } catch (error) {
      this.logger.error('Failed to get current theme week', error);
      throw error;
    }
  }

  @Post(':themeWeekId/join')
  @ApiOperation({
    summary: '加入主题周挑战',
    description: '用户加入指定的主题周挑战'
  })
  @ApiResponse({
    status: 200,
    description: '成功加入主题周',
    type: JoinThemeWeekResponseDto
  })
  @ApiResponse({
    status: 400,
    description: '请求参数错误'
  })
  @ApiResponse({
    status: 404,
    description: '主题周不存在'
  })
  @ApiResponse({
    status: 409,
    description: '用户已加入该主题周'
  })
  async joinThemeWeek(
    @Param('themeWeekId') themeWeekId: string,
    @Body() joinDto: JoinThemeWeekDto,
  ): Promise<JoinThemeWeekResponseDto> {
    try {
      this.logger.debug(`User ${joinDto.userId} attempting to join theme week ${themeWeekId}`);

      if (!joinDto.userId) {
        throw new BadRequestException('User ID is required');
      }

      const result = await this.themeWeeksService.joinThemeWeek(themeWeekId, joinDto);

      if (result.success) {
        this.logger.log(`User ${joinDto.userId} successfully joined theme week ${themeWeekId}`);
      } else {
        this.logger.warn(`User ${joinDto.userId} failed to join theme week ${themeWeekId}: ${result.error?.code}`);
      }

      return result;
    } catch (error) {
      this.logger.error(`Failed to join theme week ${themeWeekId}`, error);
      throw error;
    }
  }

  @Post(':themeWeekId/update-progress')
  @ApiOperation({
    summary: '更新用户主题周进度',
    description: '当用户完成相关练习时，更新其在主题周中的进度'
  })
  @ApiResponse({
    status: 200,
    description: '成功更新进度'
  })
  @ApiResponse({
    status: 404,
    description: '用户未参与该主题周'
  })
  async updateProgress(
    @Param('themeWeekId') themeWeekId: string,
    @Body() updateDto: { userId: string; exercisesCompleted: number },
  ) {
    try {
      this.logger.debug(`Updating progress for user ${updateDto.userId} in theme week ${themeWeekId}`);

      const result = await this.themeWeeksService.updateUserProgress(
        updateDto.userId,
        themeWeekId,
        updateDto.exercisesCompleted,
      );

      this.logger.log(`Progress updated for user ${updateDto.userId}: ${updateDto.exercisesCompleted}/${result.targetExercises}`);

      return {
        success: true,
        data: result,
      };
    } catch (error) {
      this.logger.error(`Failed to update progress for theme week ${themeWeekId}`, error);
      throw error;
    }
  }
}
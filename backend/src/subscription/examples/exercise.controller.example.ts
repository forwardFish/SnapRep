import { Controller, Post, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UsageGuard } from '../guards/usage.guard';
import { ChecksUsageLimit } from '../decorators/subscription.decorators';

@ApiTags('Exercises')
@Controller('exercises')
export class ExerciseController {
  /**
   * Example: Start exercise endpoint with usage limit protection
   * Free users are limited to 3 exercises per day
   * Premium users have unlimited access
   */
  @Post('start')
  @UseGuards(JwtAuthGuard, UsageGuard)
  @ChecksUsageLimit() // This decorator tells UsageGuard to check daily limits
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start a new exercise session' })
  async startExercise(@Request() req) {
    const userId = req.user.id;

    // This endpoint will automatically:
    // 1. Check if user is authenticated (JwtAuthGuard)
    // 2. Check if user can start exercise (UsageGuard + ChecksUsageLimit)
    //    - Premium users: unlimited access
    //    - Free users: max 3 exercises per day
    //    - If limit exceeded: returns 403 with upgrade message

    // Exercise logic here...

    return {
      message: 'Exercise started successfully',
      data: {
        sessionId: 'exercise_session_id',
        userId,
      },
    };
  }

  /**
   * Example: Complete exercise endpoint
   * This should record the exercise completion for usage tracking
   */
  @Post('complete')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Complete an exercise session' })
  async completeExercise(@Request() req) {
    const userId = req.user.id;

    // Record exercise completion for usage tracking
    // This would typically be done by the service that handles exercise completion

    return {
      message: 'Exercise completed successfully',
      data: {
        userId,
        completedAt: new Date(),
      },
    };
  }
}
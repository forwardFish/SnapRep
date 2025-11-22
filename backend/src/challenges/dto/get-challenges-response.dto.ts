import { ApiProperty } from '@nestjs/swagger';

export class ChallengeItemDto {
  @ApiProperty({ example: 'clxxx...', description: 'Challenge item ID' })
  id: string;

  @ApiProperty({ example: 'umbrella', description: 'Challenge item code' })
  code: string;

  @ApiProperty({ example: 'Umbrella', description: 'Challenge item name' })
  name: string;

  @ApiProperty({ example: '🌂', description: 'Challenge item emoji' })
  emoji: string;

  @ApiProperty({ example: 3, description: 'Difficulty level (1-5 stars)' })
  difficulty: number;

  @ApiProperty({ example: 'COMMON', description: 'Base rarity level' })
  baseRarity: string;

  @ApiProperty({ example: 3, description: 'Number of exercises in challenge' })
  exerciseCount: number;

  @ApiProperty({ example: 5, description: 'Estimated completion time in minutes' })
  estimatedMinutes: number;

  @ApiProperty({ example: 'Complete workouts using an umbrella', description: 'Challenge description', required: false })
  description?: string;

  @ApiProperty({ example: 'https://example.com/icons/umbrella.png', description: 'Card icon URL', required: false })
  iconUrl?: string;

  @ApiProperty({ example: 'https://example.com/images/umbrella-bg.jpg', description: 'Card background image URL', required: false })
  imageUrl?: string;

  @ApiProperty({ example: 142, description: 'Total number of participants' })
  totalParticipants: number;

  @ApiProperty({ example: 89, description: 'Total number of completions' })
  totalCompletions: number;

  @ApiProperty({ example: 0.627, description: 'Completion rate (0-1)' })
  completionRate: number;

  @ApiProperty({ example: true, description: 'Is challenge popular' })
  isPopular: boolean;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Creation timestamp' })
  createdAt: string;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Last update timestamp' })
  updatedAt: string;
}

export class GetChallengesResponseDto {
  @ApiProperty({ type: [ChallengeItemDto], description: 'List of challenge items' })
  data: ChallengeItemDto[];

  @ApiProperty({
    description: 'Pagination information',
    example: {
      total: 12,
      page: 1,
      pageSize: 12,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    },
  })
  pagination: {
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

export class ChallengeCompletionDto {
  @ApiProperty({ example: 'clxxx...', description: 'Completion ID' })
  id: string;

  @ApiProperty({ example: 'clxxx...', description: 'User ID' })
  userId: string;

  @ApiProperty({ example: 'clxxx...', description: 'Challenge item ID' })
  challengeItemId: string;

  @ApiProperty({ example: 'COMPLETED', description: 'Completion status: STARTED, COMPLETED, ABANDONED' })
  status: string;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Start timestamp' })
  startedAt: string;

  @ApiProperty({ example: '2024-01-15T08:15:00Z', description: 'Completion timestamp', required: false })
  completedAt?: string;

  @ApiProperty({ example: 320, description: 'Actual duration in seconds', required: false })
  actualDuration?: number;

  @ApiProperty({ example: 3, description: 'Number of completed exercises' })
  completedCount: number;

  @ApiProperty({ example: 4, description: 'Difficulty felt by user (1-5 stars)', required: false })
  difficultyFelt?: number;

  @ApiProperty({ example: 5, description: 'Enjoyment rating (1-5 stars)', required: false })
  enjoymentRating?: number;

  @ApiProperty({ example: 'RARE', description: 'Badge rarity level earned', required: false })
  badgeEarned?: string;

  @ApiProperty({ example: true, description: 'Whether badge has been awarded' })
  badgeAwarded: boolean;

  @ApiProperty({ example: 150, description: 'Experience points earned' })
  xpEarned: number;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Creation timestamp' })
  createdAt: string;

  @ApiProperty({ example: '2024-01-15T08:15:00Z', description: 'Last update timestamp' })
  updatedAt: string;
}

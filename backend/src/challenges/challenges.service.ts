import { Injectable } from '@nestjs/common';
import { logger } from '../common/logger/logger';

@Injectable()
export class ChallengesService {
  constructor() {
    logger.info('ChallengesService initialized');
  }

  /**
   * Calculate badge rarity based on participant count
   * The more participants, the higher potential rarity
   */
  calculateBadgeRarity(baseRarity: string, participantCount: number): string {
    // Simple logic: every 100 participants can upgrade rarity by one level
    const rarityLevels = [
      'COMMON',
      'UNCOMMON',
      'FINE',
      'RARE',
      'ELITE',
      'EPIC',
      'MYTHIC',
      'LEGENDARY',
      'APEX',
    ];

    const baseIndex = rarityLevels.indexOf(baseRarity);
    if (baseIndex === -1) return baseRarity;

    const bonusLevels = Math.floor(participantCount / 100);
    const newIndex = Math.min(baseIndex + bonusLevels, rarityLevels.length - 1);

    return rarityLevels[newIndex];
  }

  /**
   * Calculate XP based on difficulty and completion time
   */
  calculateXP(
    difficulty: number,
    estimatedMinutes: number,
    actualDuration: number,
  ): number {
    const baseXP = difficulty * 20;
    const timeBonus =
      actualDuration < estimatedMinutes * 60 ? 50 : 0; // Bonus for completing faster than estimated

    return baseXP + timeBonus;
  }
}

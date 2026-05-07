import { expectFileContains, expectFileOmits } from '../helpers/contract-source.helper';

describe('Business flow 6: My/Profile backend contract', () => {
    it('documents current My data routes are userId-scoped, not /me-scoped REST endpoints', () => {
        expectFileContains('src/cards/cards.controller.ts', [
            "@Get('users/:userId/cards')",
            "@Get('users/:userId/cards/stats')",
        ]);
        expectFileContains('src/workout-sessions/workout-sessions.controller.ts', [
            "@Get('users/:userId/sessions')",
            "@Get('users/:userId/most-trained-exercises')",
            "@Get('users/:userId/stats')",
        ]);
        expectFileOmits('src/cards/cards.controller.ts', ['users/me/cards']);
        expectFileOmits('src/workout-sessions/workout-sessions.controller.ts', [
            'users/me/workout-sessions',
            'users/me/profile',
        ]);
    });

    it('documents GraphQL me exists but REST My/profile endpoints are not implemented', () => {
        expectFileContains('src/users/users.resolver.ts', [
            'async me(@UserEntity() user: User): Promise<User>',
        ]);
        expectFileOmits('src/users', ['@Controller', 'users/me/profile', 'users/me/settings']);
    });

    it('documents current query DTOs for history/stats pagination', () => {
        expectFileContains('src/workout-sessions/dto/workout-session.dto.ts', [
            'export class SessionQueryDto',
            'status?: string',
            'fromDate?: string',
            'toDate?: string',
            'limit?: number = 20',
            'offset?: number = 0',
            'export class UserStatsQueryDto',
            'days?: number = 30',
        ]);
        expectFileContains('src/cards/dto/cards.dto.ts', [
            'export class CardsQueryDto',
            'rarity?: RarityLevel',
            'equipmentSeries?: string',
            'fromDate?: string',
            'toDate?: string',
            'limit?: number = 20',
            'offset?: number = 0',
        ]);
    });
});

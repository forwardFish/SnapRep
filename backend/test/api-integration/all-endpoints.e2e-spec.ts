import {
    expectFileContains,
    expectFileOmits,
    readBackendFile,
} from '../helpers/contract-source.helper';

describe('API Integration Contract - Current Backend Routes', () => {
    describe('Guide/catalog API surface', () => {
        it('documents current catalog REST routes used by Guide', () => {
            expectFileContains('src/scenarios/scenarios.controller.ts', [
                "@Controller('rest/v1/scenarios')",
                '@Get()',
                "@Get(':id')",
                "@Get('code/:code')",
            ]);

            expectFileContains('src/equipment/equipment.controller.ts', [
                "@Controller('rest/v1/equipment')",
                '@Get()',
                "@Get(':id')",
                "@Get('code/:code')",
            ]);
        });

        it('keeps dedicated workout-guide APIs out of the current contract', () => {
            expectFileOmits('src', [
                "@Controller('api/v1/workout-guide')",
                "@Controller('workout-guide')",
            ]);
        });
    });

    describe('Recommendation API surface', () => {
        it('documents current quick recommendation and helper routes', () => {
            expectFileContains('src/exercises/exercises.controller.ts', [
                "@Controller('api/v1/recommendations')",
                "@Post('quick')",
                "@Post('replace')",
                "@Get('alternatives')",
                "@Get('popular-exercises')",
            ]);
        });
    });

    describe('Workout session API surface', () => {
        it('documents current session lifecycle routes', () => {
            expectFileContains('src/workout-sessions/workout-sessions.controller.ts', [
                "@Controller('api/v1')",
                "@Post('workout-sessions')",
                "@Post('workout-sessions/from-recommendation')",
                "@Get('workout-sessions/:id')",
                "@Patch('workout-sessions/:id')",
                "@Post('workout-sessions/:id/complete')",
                "@Post('workout-sessions/:id/abandon')",
            ]);
        });
    });

    describe('Card and My/Profile API surface', () => {
        it('documents current card generation, retrieval, and user-scoped collection routes', () => {
            expectFileContains('src/cards/cards.controller.ts', [
                "@Controller('api/v1')",
                "@Post('cards/generate')",
                "@Get('cards/:id')",
                "@Get('cards/session/:sessionId')",
                "@Get('users/:userId/cards')",
                "@Get('users/:userId/cards/stats')",
            ]);
        });

        it('documents current My/Profile session and stats routes', () => {
            expectFileContains('src/workout-sessions/workout-sessions.controller.ts', [
                "@Get('users/:userId/sessions')",
                "@Get('users/:userId/most-trained-exercises')",
                "@Get('users/:userId/stats')",
            ]);
        });

        it('keeps /api/v1/users/me routes out of the current contract', () => {
            expectFileOmits('src', [
                "@Get('users/me/cards')",
                "@Get('users/me/sessions')",
                "@Controller('api/v1/users/me')",
            ]);
        });
    });

    describe('Auth and theme-week API surface', () => {
        it('documents current auth routes and absence of anonymous auth', () => {
            expectFileContains('src/auth/auth.controller.ts', [
                "@Controller('rest/v1/auth')",
                "@Post('register')",
                "@Post('login')",
                "@Post('otp/send')",
                "@Post('otp/verify')",
                "@Post('google')",
                "@Post('refresh')",
                "@Get('me')",
                "@Post('logout')",
            ]);
            expectFileOmits('src/auth/auth.controller.ts', ["@Post('anonymous')"]);
        });

        it('documents current theme-week routes', () => {
            expectFileContains('src/theme-weeks/theme-weeks.controller.ts', [
                "@Controller('/api/v1/theme-weeks')",
                "@Get('current')",
                "@Post(':themeWeekId/join')",
                "@Post(':themeWeekId/update-progress')",
            ]);
        });
    });

    describe('Current Prisma schema contract', () => {
        it('documents current field names that replaced stale API-test assumptions', () => {
            const schema = readBackendFile('prisma/schema.prisma');

            expect(schema).toContain('id String @id @default(cuid())');
            expect(schema).toContain('model WorkoutSession');
            expect(schema).toContain('scenarioId    String?         @map("scenario_id")');
            expect(schema).toContain('model UserPreference');
            expect(schema).toContain('preferenceType  String @map("preference_type")');
            expect(schema).toContain('preferenceKey   String @map("preference_key")');
            expect(schema).toContain('preferenceValue Float  @map("preference_value")');
            expect(schema).toContain('model DailyTraining');
            expect(schema).toContain('totalSessions     Int @default(0) @map("total_sessions")');
            expect(schema).toContain('totalExercises    Int @default(0) @map("total_exercises")');
            expect(schema).toContain('model ThemeWeek');
            expect(schema).toContain('title       String');
            expect(schema).toContain('equipmentCode       String @map("equipment_code")');
            expect(schema).not.toContain('isAnonymous');
        });
    });
});

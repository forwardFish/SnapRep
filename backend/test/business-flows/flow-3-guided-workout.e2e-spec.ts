import { expectFileContains, expectFileOmits } from '../helpers/contract-source.helper';

describe('Business flow 3: workout session contract', () => {
    it('documents that dedicated workout-guide step routes are not current backend API', () => {
        expectFileOmits('src/app.module.ts', ['WorkoutGuideModule']);
        expectFileOmits('src', ['workout-guide/step1', 'workout-guide/complete']);
    });

    it('documents current workout-session endpoints for the post-recommendation flow', () => {
        expectFileContains('src/workout-sessions/workout-sessions.controller.ts', [
            "@Controller('api/v1')",
            "@Post('workout-sessions')",
            "@Post('workout-sessions/from-recommendation')",
            "@Get('workout-sessions/:id')",
            "@Patch('workout-sessions/:id')",
            "@Post('workout-sessions/:id/complete')",
            "@Post('workout-sessions/:id/abandon')",
            "@Get('users/:userId/sessions')",
            "@Get('users/:userId/stats')",
        ]);
    });

    it('documents create/update/complete DTO fields', () => {
        expectFileContains('src/workout-sessions/dto/workout-session.dto.ts', [
            'export class CreateWorkoutSessionDto',
            'userId: string',
            'intentType: IntentType',
            'scenarioId?: string',
            'targetMuscles?: string[]',
            'totalDuration: number',
            'difficulty: Difficulty',
            'exercises: CreateSessionExerciseDto[]',
            'export class UpdateWorkoutSessionDto',
            'status?: SessionStatus',
            'actualDuration?: number',
            'rating?: number',
            'feedback?: string',
        ]);
    });

    it('documents current schema uses scenarioId relation, not stale scenarioCode field', () => {
        expectFileContains('prisma/schema.prisma', [
            'model WorkoutSession {',
            'scenarioId    String?         @map("scenario_id")',
            'sessionExercises     SessionExercise[]',
            '@@map("workout_sessions")',
        ]);
        expectFileOmits('prisma/schema.prisma', ['scenarioCode']);
    });
});

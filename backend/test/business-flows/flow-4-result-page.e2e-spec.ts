import { expectFileContains } from '../helpers/contract-source.helper';

describe('Business flow 4: result and card-generation boundary contract', () => {
    it('documents result-page recommendation support endpoints', () => {
        expectFileContains('src/exercises/exercises.controller.ts', [
            "@Post('quick')",
            "@Post('replace')",
            "@Get('alternatives')",
            "@Get('popular-exercises')",
        ]);
    });

    it('documents completion endpoint used before card generation', () => {
        expectFileContains('src/workout-sessions/workout-sessions.controller.ts', [
            "@Post('workout-sessions/:id/complete')",
            'actualDuration?: number',
            'rating?: number',
            'feedback?: string',
        ]);
    });

    it('documents card generation route and payload', () => {
        expectFileContains('src/cards/cards.controller.ts', [
            "@Post('cards/generate')",
            'generateCard(@Body(ValidationPipe) generateDto: GenerateCardDto)',
        ]);
        expectFileContains('src/cards/dto/cards.dto.ts', [
            'export class GenerateCardDto',
            'sessionId: string',
            "cardTemplate?: string = 'classic'",
            'shareText?: string',
            'isPublic?: boolean = true',
            'specialTags?: string[] = []',
            'themeWeek?: string',
            'forceRegenerate?: boolean = false',
        ]);
    });

    it('captures the current sessionId validator mismatch as a documented test-contract risk', () => {
        expectFileContains('src/cards/dto/cards.dto.ts', ['@IsUUID()', 'sessionId: string']);
        expectFileContains('prisma/schema.prisma', [
            'model WorkoutSession {',
            'id     String @id @default(cuid())',
        ]);
    });
});

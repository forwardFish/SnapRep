import { expectFileContains, expectFileOmits } from '../helpers/contract-source.helper';

describe('Business flow 2: guide input to recommendation contract', () => {
    it('documents the current quick recommendation endpoint', () => {
        expectFileContains('src/exercises/exercises.controller.ts', [
            "@Controller('api/v1/recommendations')",
            "@Post('quick')",
            '@HttpCode(HttpStatus.OK)',
            'generateQuickRecommendation(dto)',
        ]);
    });

    it('documents accepted guide/recommendation payload fields', () => {
        expectFileContains('src/exercises/dto/exercise-recommendation.dto.ts', [
            'export class QuickRecommendationDto',
            'userId?: string',
            'intent?: IntentType',
            'intents?: IntentType[]',
            'equipment?: string[]',
            'equipmentCodes?: string[]',
            'scenario?: string',
            'scenarioCode?: string',
            'targetMuscles?: PrimaryMuscle[]',
            '@Min(30)',
            '@Max(600)',
            'duration?: number = 60',
            'difficulty?: Difficulty',
            'themeWeekId?: string',
            'currentStep?: number',
        ]);
    });

    it('documents the current enum contract used by recommendation inputs', () => {
        expectFileContains('prisma/schema.prisma', [
            'enum IntentType {',
            'RELAX',
            'STRETCH',
            'MODERATE',
            'STRENGTH',
            'enum Difficulty {',
            'GREEN',
            'BLUE',
            'RED',
            'enum PrimaryMuscle {',
            'FULL_BODY',
        ]);
    });

    it('documents stale split recommendation/AI routes as not current production API', () => {
        expectFileOmits('src/exercises/exercises.controller.ts', [
            "@Post('scenario')",
            "@Post('with-equipment')",
        ]);
        expectFileOmits('src', ['recognize-equipment']);
    });
});

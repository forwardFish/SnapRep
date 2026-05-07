import { expectFileContains, expectFileOmits } from '../helpers/contract-source.helper';

describe('Business flow 7: theme-week contract', () => {
    it('documents current theme-week endpoints', () => {
        expectFileContains('src/theme-weeks/theme-weeks.controller.ts', [
            "@Controller('/api/v1/theme-weeks')",
            "@Get('current')",
            "@Post(':themeWeekId/join')",
            "@Post(':themeWeekId/update-progress')",
        ]);
    });

    it('documents current theme-week response/model naming', () => {
        expectFileContains('src/theme-weeks/theme-weeks.controller.ts', [
            'equipmentCode: currentThemeWeek.equipment_code',
            'targetExerciseCount: currentThemeWeek.target_exercise_count || 3',
            'globalStats',
            'participation',
        ]);
        expectFileContains('prisma/schema.prisma', [
            'model ThemeWeek {',
            'title       String',
            'equipmentCode       String @map("equipment_code")',
            'targetExerciseCount Int    @default(3) @map("target_exercise_count")',
            'rewardType String @map("reward_type")',
        ]);
    });

    it('documents old theme-week field names as stale test contract', () => {
        expectFileOmits('prisma/schema.prisma', [
            'equipmentSeries String @map("equipment_series") // theme week',
            'targetCount',
        ]);
        expectFileOmits('src/theme-weeks/theme-weeks.controller.ts', [
            'equipmentSeries',
            'targetCount',
        ]);
    });

    it('documents participation fields used by My/theme progress', () => {
        expectFileContains('prisma/schema.prisma', [
            'model ThemeWeekParticipation {',
            'exercisesCompleted Int   @default(0) @map("exercises_completed")',
            'targetExercises    Int   @map("target_exercises")',
            'progressPercent    Float @default(0.0) @map("progress_percent")',
            'rewardEarned    Boolean   @default(false)',
            'relatedSessions String[] @default([])',
        ]);
    });
});

import { expectFileContains } from '../helpers/contract-source.helper';

describe('Business flow 5: result card persistence and retrieval contract', () => {
    it('documents current card retrieval and collection endpoints', () => {
        expectFileContains('src/cards/cards.controller.ts', [
            "@Get('cards/public')",
            "@Get('cards/health')",
            "@Get('cards/:id')",
            "@Get('cards/session/:sessionId')",
            "@Get('users/:userId/cards')",
            "@Patch('cards/:id')",
            "@Post('cards/:id/share')",
            "@Get('users/:userId/cards/stats')",
        ]);
    });

    it('documents current rarity endpoints', () => {
        expectFileContains('src/cards/cards.controller.ts', [
            "@Get('rarity/calculate/:code')",
            "@Post('rarity/calculate-batch')",
            "@Get('rarity/ranking')",
            "@Get('rarity/:code/trend')",
        ]);
    });

    it('documents ShareCard persistence fields', () => {
        expectFileContains('prisma/schema.prisma', [
            'model ShareCard {',
            'userId String @map("user_id")',
            'sessionId String         @unique @map("session_id")',
            'cardImageUrl String @map("card_image_url")',
            'cardTemplate String @map("card_template")',
            'rarity          RarityLevel @map("rarity")',
            'personalStars   Int         @default(1)',
            'equipmentSeries String      @map("equipment_series")',
            'specialTags String[] @default([])',
            'shareCount Int @default(0)',
            'viewCount  Int @default(0)',
        ]);
    });
});

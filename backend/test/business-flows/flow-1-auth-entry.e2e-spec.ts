import { expectFileContains, expectFileOmits } from '../helpers/contract-source.helper';

describe('Business flow 1: auth entry and catalog contract', () => {
    it('documents the current auth controller routes', () => {
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
    });

    it('documents that anonymous-user auth is not a current schema/API contract', () => {
        expectFileOmits('src/auth/auth.controller.ts', ['anonymous']);
        expectFileOmits('prisma/schema.prisma', ['isAnonymous']);
        expectFileContains('prisma/schema.prisma', [
            'model User {',
            'email     String? @unique',
            'name      String?',
            'avatarUrl String? @map("avatar_url")',
            'subscriptionTier   SubscriptionTier',
        ]);
    });

    it('keeps guide catalog entrypoints grounded in current REST controllers', () => {
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
            "@Get('category/grouped')",
        ]);
    });
});

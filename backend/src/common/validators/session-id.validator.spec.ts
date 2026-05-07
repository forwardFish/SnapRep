import { validate } from 'class-validator';
import { IsSessionId, isSessionId } from './session-id.validator';

class SessionIdFixture {
    @IsSessionId()
    sessionId: string;
}

describe('SessionId validator', () => {
    it('accepts current Prisma CUID session ids', async () => {
        const value = 'cm9stage2cruntimee2eid01';
        const dto = new SessionIdFixture();
        dto.sessionId = value;

        expect(isSessionId(value)).toBe(true);
        await expect(validate(dto)).resolves.toHaveLength(0);
    });

    it('keeps UUID compatibility for legacy callers', async () => {
        const value = '550e8400-e29b-41d4-a716-446655440000';
        const dto = new SessionIdFixture();
        dto.sessionId = value;

        expect(isSessionId(value)).toBe(true);
        await expect(validate(dto)).resolves.toHaveLength(0);
    });

    it('rejects unsafe arbitrary strings', async () => {
        const dto = new SessionIdFixture();
        dto.sessionId = 'test-session';

        expect(isSessionId(dto.sessionId)).toBe(false);
        await expect(validate(dto)).resolves.toHaveLength(1);
    });
});

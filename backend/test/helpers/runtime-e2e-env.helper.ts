export interface RuntimeE2EConfig {
    enabled: boolean;
    allowReset: boolean;
    databaseUrl?: string;
    directUrl?: string;
    testUserId: string;
    testUserEmail: string;
}

const PROD_HOST_HINTS = [
    'tvjcmleckqovnieuexgu.supabase.co',
    'supabase.co',
    'amazonaws.com',
    'rds.amazonaws.com',
    'database.windows.net',
];

export function redactUrl(rawUrl?: string): string {
    if (!rawUrl) return '';
    try {
        const parsed = new URL(rawUrl);
        if (parsed.username) parsed.username = '***';
        if (parsed.password) parsed.password = '***';
        return parsed.toString();
    } catch (_) {
        return '<invalid-url>';
    }
}

export function isSafeTestDatabaseUrl(rawUrl?: string): boolean {
    if (!rawUrl) return false;

    try {
        const parsed = new URL(rawUrl);
        const host = parsed.hostname.toLowerCase();
        const dbName = parsed.pathname.replace(/^\//, '').toLowerCase();
        const full = rawUrl.toLowerCase();

        if (!['postgresql:', 'postgres:'].includes(parsed.protocol)) return false;
        if (PROD_HOST_HINTS.some(hint => host.includes(hint))) return false;

        return (
            dbName.includes('test') ||
            dbName.includes('snaprep_test') ||
            full.includes('localhost') ||
            full.includes('127.0.0.1')
        );
    } catch (_) {
        return false;
    }
}

export function getRuntimeE2EConfig(env: NodeJS.ProcessEnv = process.env): RuntimeE2EConfig {
    const databaseUrl = env.TEST_DATABASE_URL || env.DATABASE_URL;
    const directUrl = env.TEST_DIRECT_URL || env.DIRECT_URL || databaseUrl;

    return {
        enabled: env.SNAPREP_RUNTIME_E2E === '1' || env.SNAPREP_RUNTIME_E2E === 'true',
        allowReset: env.SNAPREP_E2E_ALLOW_DB_RESET === '1',
        databaseUrl,
        directUrl,
        testUserId: env.SNAPREP_E2E_USER_ID || '00000000-0000-4000-8000-0000000002c0',
        testUserEmail: env.SNAPREP_E2E_USER_EMAIL || 'stage2c-runtime@snaprep.test',
    };
}

export function assertRuntimeE2ESafe(options: { destructive?: boolean } = {}): RuntimeE2EConfig {
    const config = getRuntimeE2EConfig();

    if (!config.enabled) {
        throw new Error(
            'Runtime E2E disabled. Set SNAPREP_RUNTIME_E2E=1 to run DB-backed runtime E2E.'
        );
    }
    if (process.env.SNAPREP_E2E_ENV !== 'test') {
        throw new Error('SNAPREP_E2E_ENV must be exactly "test" for runtime E2E.');
    }
    if (!isSafeTestDatabaseUrl(config.databaseUrl)) {
        throw new Error(
            `Refusing unsafe runtime E2E database URL: ${redactUrl(config.databaseUrl)}`
        );
    }
    if (options.destructive && !config.allowReset) {
        throw new Error('Destructive runtime E2E reset requires SNAPREP_E2E_ALLOW_DB_RESET=1.');
    }

    return config;
}

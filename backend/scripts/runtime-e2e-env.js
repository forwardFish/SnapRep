const { URL } = require('url');

const PROD_HOST_HINTS = [
    'tvjcmleckqovnieuexgu.supabase.co',
    'supabase.co',
    'amazonaws.com',
    'rds.amazonaws.com',
    'database.windows.net',
];

function redactUrl(rawUrl) {
    if (!rawUrl) return '';
    try {
        const parsed = new URL(rawUrl);
        if (parsed.password) parsed.password = '***';
        if (parsed.username) parsed.username = parsed.username ? '***' : '';
        return parsed.toString();
    } catch (_) {
        return '<invalid-url>';
    }
}

function parseDatabaseUrl(rawUrl) {
    try {
        return new URL(rawUrl);
    } catch (error) {
        throw new Error(`Invalid database URL: ${error.message}`);
    }
}

function isSafeTestDatabaseUrl(rawUrl) {
    if (!rawUrl) return false;
    const parsed = parseDatabaseUrl(rawUrl);
    const host = parsed.hostname.toLowerCase();
    const dbName = parsed.pathname.replace(/^\//, '').toLowerCase();
    const full = rawUrl.toLowerCase();

    if (!['postgresql:', 'postgres:'].includes(parsed.protocol)) {
        return false;
    }

    if (PROD_HOST_HINTS.some(hint => host.includes(hint))) {
        return false;
    }

    return (
        dbName.includes('test') ||
        dbName.includes('snaprep_test') ||
        full.includes('localhost') ||
        full.includes('127.0.0.1')
    );
}

function getRuntimeE2EConfig(env = process.env) {
    const enabled = env.SNAPREP_RUNTIME_E2E === '1' || env.SNAPREP_RUNTIME_E2E === 'true';
    const allowReset = env.SNAPREP_E2E_ALLOW_DB_RESET === '1';
    const databaseUrl = env.TEST_DATABASE_URL || env.DATABASE_URL;
    const directUrl = env.TEST_DIRECT_URL || env.DIRECT_URL || databaseUrl;

    return {
        enabled,
        allowReset,
        databaseUrl,
        directUrl,
        testUserId: env.SNAPREP_E2E_USER_ID || '00000000-0000-4000-8000-0000000002c0',
        testUserEmail: env.SNAPREP_E2E_USER_EMAIL || 'stage2c-runtime@snaprep.test',
    };
}

function assertRuntimeE2ESafe({ destructive = false, env = process.env } = {}) {
    const config = getRuntimeE2EConfig(env);

    if (!config.enabled) {
        throw new Error(
            'Runtime E2E is disabled. Set SNAPREP_RUNTIME_E2E=1 to run DB-backed runtime E2E.'
        );
    }

    if (env.SNAPREP_E2E_ENV !== 'test') {
        throw new Error('SNAPREP_E2E_ENV must be exactly "test" for runtime E2E.');
    }

    if (!config.databaseUrl) {
        throw new Error('TEST_DATABASE_URL or DATABASE_URL is required for runtime E2E.');
    }

    if (!isSafeTestDatabaseUrl(config.databaseUrl)) {
        throw new Error(
            `Refusing unsafe runtime E2E database URL: ${redactUrl(config.databaseUrl)}`
        );
    }

    if (destructive && !config.allowReset) {
        throw new Error('Destructive E2E reset requires SNAPREP_E2E_ALLOW_DB_RESET=1.');
    }

    return config;
}

module.exports = {
    assertRuntimeE2ESafe,
    getRuntimeE2EConfig,
    isSafeTestDatabaseUrl,
    redactUrl,
};

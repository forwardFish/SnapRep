const { spawnSync } = require('child_process');
const { assertRuntimeE2ESafe, redactUrl } = require('./runtime-e2e-env');

const DEFAULT_TEST_DATABASE_URL =
    'postgresql://snaprep_test:snaprep_test@127.0.0.1:55432/snaprep_test';

function applyLocalDefaults() {
    process.env.SNAPREP_RUNTIME_E2E = process.env.SNAPREP_RUNTIME_E2E || '1';
    process.env.SNAPREP_E2E_ENV = process.env.SNAPREP_E2E_ENV || 'test';
    process.env.SNAPREP_E2E_ALLOW_DB_RESET = process.env.SNAPREP_E2E_ALLOW_DB_RESET || '1';
    process.env.TEST_DATABASE_URL = process.env.TEST_DATABASE_URL || DEFAULT_TEST_DATABASE_URL;
    process.env.TEST_DIRECT_URL = process.env.TEST_DIRECT_URL || process.env.TEST_DATABASE_URL;
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.DIRECT_URL = process.env.TEST_DIRECT_URL;
}

function run(command, args) {
    console.log(`> ${command} ${args.join(' ')}`);
    const result = spawnSync(command, args, {
        cwd: process.cwd(),
        env: process.env,
        stdio: 'inherit',
        shell: process.platform === 'win32',
    });
    if (result.status !== 0) {
        process.exit(result.status || 1);
    }
}

function printSafeEnv() {
    const config = assertRuntimeE2ESafe({ destructive: true });
    console.log('Runtime E2E DB environment is enabled.');
    console.log(`TEST_DATABASE_URL=${redactUrl(config.databaseUrl)}`);
    console.log(`TEST_DIRECT_URL=${redactUrl(config.directUrl)}`);
    console.log(`SNAPREP_E2E_ENV=${process.env.SNAPREP_E2E_ENV}`);
    console.log(`SNAPREP_E2E_ALLOW_DB_RESET=${process.env.SNAPREP_E2E_ALLOW_DB_RESET}`);
}

function pushSchema() {
    assertRuntimeE2ESafe();
    run('npx', ['prisma', 'db', 'push', '--skip-generate']);
}

function seed() {
    assertRuntimeE2ESafe({ destructive: true });
    run('node', ['scripts/runtime-e2e-seed.js', 'seed']);
}

function reset() {
    assertRuntimeE2ESafe({ destructive: true });
    run('node', ['scripts/runtime-e2e-seed.js', 'reset']);
}

function test() {
    assertRuntimeE2ESafe({ destructive: true });
    run('npm', ['run', 'test:e2e:runtime']);
}

function main() {
    const command = process.argv[2] || 'test';
    applyLocalDefaults();

    if (command === 'print-env') return printSafeEnv();
    if (command === 'push') return pushSchema();
    if (command === 'seed') return seed();
    if (command === 'reset') return reset();
    if (command === 'test') return test();
    if (command === 'all') {
        printSafeEnv();
        pushSchema();
        seed();
        test();
        return;
    }

    console.error('Usage: node scripts/runtime-e2e-db.js <print-env|push|seed|reset|test|all>');
    process.exit(2);
}

main();

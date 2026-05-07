const fs = require('fs');
const http = require('http');
const path = require('path');

const backendRoot = path.resolve(__dirname, '..');
const mode = process.env.SNAPREP_HEALTH_MODE || 'source';
const baseUrl = process.env.SNAPREP_HEALTH_BASE_URL || 'http://127.0.0.1:3000';

const sourceChecks = [
    {
        name: 'recommendation quick route',
        file: 'src/exercises/exercises.controller.ts',
        snippets: ["@Controller('api/v1/recommendations')", "@Post('quick')"],
        critical: true,
    },
    {
        name: 'card health/generation routes',
        file: 'src/cards/cards.controller.ts',
        snippets: [
            "@Post('cards/generate')",
            "@Get('cards/health')",
            "@Get('users/:userId/cards')",
        ],
        critical: true,
    },
    {
        name: 'workout session current routes',
        file: 'src/workout-sessions/workout-sessions.controller.ts',
        snippets: [
            "@Post('workout-sessions')",
            "@Post('workout-sessions/from-recommendation')",
            "@Get('workout-sessions/:id')",
            "@Post('workout-sessions/:id/complete')",
            "@Get('users/:userId/sessions')",
            "@Get('users/:userId/stats')",
        ],
        critical: true,
    },
    {
        name: 'catalog routes',
        file: 'src/scenarios/scenarios.controller.ts',
        snippets: ["@Controller('rest/v1/scenarios')", '@Get()'],
        critical: true,
    },
    {
        name: 'equipment routes',
        file: 'src/equipment/equipment.controller.ts',
        snippets: ["@Controller('rest/v1/equipment')", '@Get()'],
        critical: true,
    },
    {
        name: 'theme week current route',
        file: 'src/theme-weeks/theme-weeks.controller.ts',
        snippets: ["@Controller('/api/v1/theme-weeks')", "@Get('current')"],
        critical: false,
    },
];

const networkChecks = [
    { method: 'GET', path: '/api', critical: true },
    { method: 'GET', path: '/api/v1/cards/health', critical: true },
    { method: 'GET', path: '/rest/v1/scenarios', critical: true },
    { method: 'GET', path: '/rest/v1/equipment', critical: true },
    { method: 'GET', path: '/api/v1/theme-weeks/current', critical: false },
];

function checkSource() {
    const results = sourceChecks.map(check => {
        const fullPath = path.join(backendRoot, check.file);
        const content = fs.readFileSync(fullPath, 'utf8');
        const missing = check.snippets.filter(snippet => !content.includes(snippet));
        return { ...check, status: missing.length === 0 ? 'healthy' : 'unhealthy', missing };
    });

    console.log('SnapRep backend health check (source mode)');
    for (const result of results) {
        const icon = result.status === 'healthy' ? 'OK' : 'FAIL';
        console.log(
            `${icon} ${result.name}${
                result.missing.length ? ` missing: ${result.missing.join(', ')}` : ''
            }`
        );
    }

    const failedCritical = results.filter(result => result.critical && result.status !== 'healthy');
    console.log(
        `Health summary: ${results.length - failedCritical.length}/${
            results.length
        } checks healthy; critical failures: ${failedCritical.length}`
    );
    return failedCritical.length === 0 ? 0 : 1;
}

function requestEndpoint(endpoint) {
    const url = new URL(endpoint.path, baseUrl);
    return new Promise(resolve => {
        const req = http.request(
            url,
            {
                method: endpoint.method,
                timeout: 5000,
                headers: { 'Content-Type': 'application/json' },
            },
            res => {
                res.resume();
                resolve({ ...endpoint, statusCode: res.statusCode, healthy: res.statusCode < 500 });
            }
        );
        req.on('timeout', () => {
            req.destroy();
            resolve({ ...endpoint, statusCode: 0, healthy: false, error: 'timeout' });
        });
        req.on('error', error =>
            resolve({ ...endpoint, statusCode: 0, healthy: false, error: error.message })
        );
        req.end();
    });
}

async function checkNetwork() {
    console.log(`SnapRep backend health check (network mode): ${baseUrl}`);
    const results = [];
    for (const endpoint of networkChecks) {
        const result = await requestEndpoint(endpoint);
        results.push(result);
        const icon = result.healthy ? 'OK' : 'FAIL';
        console.log(
            `${icon} ${endpoint.method} ${endpoint.path} status=${result.statusCode}${
                result.error ? ` error=${result.error}` : ''
            }`
        );
    }
    const failedCritical = results.filter(result => result.critical && !result.healthy);
    console.log(`Health summary: critical failures: ${failedCritical.length}`);
    return failedCritical.length === 0 ? 0 : 1;
}

(async () => {
    if (mode === 'network') {
        process.exit(await checkNetwork());
    }
    if (mode !== 'source') {
        console.error(`Unknown SNAPREP_HEALTH_MODE=${mode}. Use source or network.`);
        process.exit(2);
    }
    process.exit(checkSource());
})();

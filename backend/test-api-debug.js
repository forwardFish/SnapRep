#!/usr/bin/env node

/**
 * Detailed API Error Investigation
 */

const { execSync } = require('child_process');

const baseUrl = 'http://localhost:3000';

function checkEndpoint(name, url, method = 'GET', data = null) {
  let command;

  if (method === 'GET') {
    command = `curl -i -s ${url}`;
  } else {
    const dataStr = data ? JSON.stringify(data).replace(/"/g, '\\"') : '{}';
    command = `curl -i -s -X ${method} ${url} -H "Content-Type: application/json" -d "${dataStr}"`;
  }

  try {
    const output = execSync(command, {
      encoding: 'utf8',
      timeout: 10000
    });

    console.log(`\n🔍 ${name}`);
    console.log(`URL: ${url}`);
    console.log(`Method: ${method}`);
    if (data) console.log(`Data: ${JSON.stringify(data)}`);
    console.log('Response:');
    console.log(output);
    console.log('-'.repeat(80));

  } catch (error) {
    console.log(`\n❌ ${name} - ERROR`);
    console.log(`Command: ${command}`);
    console.log(`Error: ${error.message}`);
    console.log('-'.repeat(80));
  }
}

console.log('🔍 Detailed API Error Investigation');
console.log('='.repeat(80));

// Check the failed endpoints
checkEndpoint('Quick Recommendation', `${baseUrl}/api/v1/recommendations/quick`, 'POST', {
  userId: 'anonymous-user',
  intents: ['RELAX'],
  scenario: null,
  equipment: [],
  targetMuscles: ['FULL_BODY'],
  currentStep: 3
});

checkEndpoint('Workout Sessions Health', `${baseUrl}/api/v1/workout-sessions/health`);

checkEndpoint('Cards Health', `${baseUrl}/api/v1/cards/health`);

checkEndpoint('Public Cards', `${baseUrl}/api/v1/cards/public`);

checkEndpoint('Analytics Cohorts', `${baseUrl}/api/v1/analytics/cohorts`);

// Also check a working endpoint for comparison
checkEndpoint('Scenarios (Working)', `${baseUrl}/rest/v1/scenarios`);
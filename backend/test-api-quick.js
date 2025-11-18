#!/usr/bin/env node

/**
 * Quick API Test using curl commands
 */

const { execSync } = require('child_process');
const fs = require('fs');

// 配置
const baseUrl = 'http://localhost:3000';
const admin = {
  email: 'admin@snaprep.com',
  password: 'Linlin@123'
};

const results = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: []
};

// 简化的测试函数
function runTest(name, curlCommand) {
  results.total++;

  try {
    console.log(`\n🧪 Testing: ${name}`);
    console.log(`Command: ${curlCommand}`);

    const output = execSync(curlCommand, {
      timeout: 10000,
      encoding: 'utf8'
    });

    results.passed++;
    console.log(`✅ ${name}: SUCCESS`);

    // 显示部分响应
    if (output.length > 500) {
      console.log(`📄 Response (truncated): ${output.substring(0, 500)}...`);
    } else {
      console.log(`📄 Response: ${output}`);
    }

    return output;
  } catch (error) {
    results.failed++;
    console.log(`❌ ${name}: FAILED`);
    console.log(`💥 Error: ${error.message}`);

    results.errors.push({
      name,
      command: curlCommand,
      error: error.message
    });

    return null;
  }
}

// 认证测试
function testAuth() {
  console.log('\n🔐 认证模块测试');

  // 登录获取token
  const loginCommand = `curl -s -f -X POST ${baseUrl}/rest/v1/auth/login -H "Content-Type: application/json" -d "${JSON.stringify(admin).replace(/"/g, '\\"')}"`;
  const loginResponse = runTest('管理员登录', loginCommand);

  let token = null;
  let userId = null;

  if (loginResponse) {
    try {
      const loginData = JSON.parse(loginResponse);
      token = loginData.accessToken;
      userId = loginData.user?.id;
      console.log(`🔑 Token获取成功, UserID: ${userId || 'N/A'}`);
    } catch (error) {
      console.log(`⚠️ 解析登录响应失败: ${error.message}`);
    }
  }

  return { token, userId };
}

// 场景测试
function testScenarios() {
  console.log('\n🎭 场景模块测试');

  runTest('获取场景列表', `curl -s -f ${baseUrl}/rest/v1/scenarios`);
  runTest('获取场景统计', `curl -s -f ${baseUrl}/rest/v1/scenarios/stats/count`);
}

// 器材测试
function testEquipment() {
  console.log('\n🏋️ 器材模块测试');

  runTest('获取器材列表', `curl -s -f ${baseUrl}/rest/v1/equipment`);
  runTest('获取器材列表(分页)', `curl -s -f "${baseUrl}/rest/v1/equipment?page=1&pageSize=5"`);
  runTest('获取器材列表(按分类)', `curl -s -f "${baseUrl}/rest/v1/equipment?category=FURNITURE"`);
  runTest('获取活跃器材列表', `curl -s -f ${baseUrl}/rest/v1/equipment/active/list`);
}

// 推荐测试
function testRecommendations() {
  console.log('\n💪 推荐模块测试');

  const quickRecommendationData = {
    userId: 'anonymous-user',
    intents: ['RELAX'],
    scenario: null,
    equipment: [],
    targetMuscles: ['FULL_BODY'],
    currentStep: 3
  };

  const dataStr = JSON.stringify(quickRecommendationData).replace(/"/g, '\\"');
  runTest('快速推荐', `curl -s -f -X POST ${baseUrl}/api/v1/recommendations/quick -H "Content-Type: application/json" -d "${dataStr}"`);
}

// 训练会话测试
function testWorkoutSessions(token, userId) {
  console.log('\n🏃 训练会话模块测试');

  runTest('健康检查', `curl -s -f ${baseUrl}/api/v1/workout-sessions/health`);

  if (token && userId) {
    const sessionData = {
      userId,
      intentType: 'STRETCH',
      totalDuration: 300,
      difficulty: 'GREEN'
    };

    const dataStr = JSON.stringify(sessionData).replace(/"/g, '\\"');
    runTest('创建训练会话', `curl -s -f -X POST ${baseUrl}/api/v1/workout-sessions -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d "${dataStr}"`);
  } else {
    console.log('⚠️ 无token或userId，跳过需要认证的测试');
  }
}

// 卡片测试
function testCards() {
  console.log('\n🃏 卡片模块测试');

  runTest('卡片健康检查', `curl -s -f ${baseUrl}/api/v1/cards/health`);
  runTest('获取公开卡片', `curl -s -f ${baseUrl}/api/v1/cards/public`);
  runTest('获取稀有度排名', `curl -s -f ${baseUrl}/api/v1/rarity/ranking`);
}

// 分析模块测试
function testAnalytics() {
  console.log('\n📊 分析模块测试');

  runTest('获取群组分析', `curl -s -f ${baseUrl}/api/v1/analytics/cohorts`);
  runTest('获取平台KPI', `curl -s -f ${baseUrl}/api/v1/analytics/platform/kpis`);
}

// 主题周测试
function testThemeWeeks() {
  console.log('\n🎯 主题周模块测试');

  runTest('获取当前主题周', `curl -s -f ${baseUrl}/api/v1/theme-weeks/current`);
}

// 生成报告
function generateReport() {
  console.log('\n📋 测试报告');
  console.log('='.repeat(60));

  console.log(`总计测试: ${results.total}`);
  console.log(`✅ 成功: ${results.passed}`);
  console.log(`❌ 失败: ${results.failed}`);
  console.log(`成功率: ${((results.passed / results.total) * 100).toFixed(2)}%`);

  if (results.errors.length > 0) {
    console.log('\n❌ 错误详情:');
    results.errors.forEach((error, index) => {
      console.log(`\n${index + 1}. ${error.name}`);
      console.log(`   命令: ${error.command}`);
      console.log(`   错误: ${error.error}`);
    });
  }

  console.log('\n' + '='.repeat(60));

  if (results.failed === 0) {
    console.log('🎉 所有API测试通过！');
  } else {
    console.log(`❌ 发现 ${results.failed} 个问题需要修复`);
  }
}

// 主函数
async function main() {
  console.log('🚀 SnapRep 后端 API 快速测试');
  console.log(`服务地址: ${baseUrl}`);

  // 检查服务是否可用
  try {
    execSync(`curl -s -f ${baseUrl}/rest/v1/scenarios`, { timeout: 5000 });
    console.log('✅ 后端服务检测成功');
  } catch (error) {
    console.log('❌ 后端服务不可用，请确保服务已启动');
    console.log(`错误: ${error.message}`);
    return;
  }

  try {
    const { token, userId } = testAuth();
    testScenarios();
    testEquipment();
    testRecommendations();
    testWorkoutSessions(token, userId);
    testCards();
    testAnalytics();
    testThemeWeeks();

    generateReport();
  } catch (error) {
    console.log(`测试执行失败: ${error.message}`);
  }
}

// 执行测试
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { main };
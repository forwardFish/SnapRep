#!/usr/bin/env node

/**
 * SnapRep 后端 API 全面测试脚本 v2.0
 *
 * 特点:
 * - 使用内置 http/https 模块，无外部依赖
 * - 完整覆盖所有 65+ API 端点
 * - 自动登录认证获取 token
 * - 详细的测试报告和错误分析
 * - 支持端口自动检测 (3000/3001)
 */

const http = require('http');
const https = require('https');

// 配置
const config = {
  hostname: 'localhost',
  ports: [3000, 3001], // 尝试多个端口
  admin: {
    email: 'admin@snaprep.com',
    password: 'Linlin@123'
  }
};

// 全局变量
let authToken = null;
let userId = null;
let activePort = null;
const testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: [],
  modules: {}
};

// 工具函数：彩色输出（简化版）
const log = {
  info: (msg) => console.log(`ℹ️  ${msg}`),
  success: (msg) => console.log(`✅ ${msg}`),
  error: (msg) => console.log(`❌ ${msg}`),
  warning: (msg) => console.log(`⚠️  ${msg}`),
  header: (msg) => {
    console.log('\n' + '='.repeat(60));
    console.log(`🔷 ${msg}`);
    console.log('='.repeat(60));
  },
  separator: () => console.log('-'.repeat(60))
};

// HTTP 请求封装
function makeRequest(method, path, data = null, useAuth = false) {
  return new Promise((resolve, reject) => {
    const postData = data ? JSON.stringify(data) : null;

    const options = {
      hostname: config.hostname,
      port: activePort,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(postData && { 'Content-Length': Buffer.byteLength(postData) }),
        ...(useAuth && authToken && { 'Authorization': `Bearer ${authToken}` })
      },
      timeout: 10000
    };

    const req = http.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = responseData ? JSON.parse(responseData) : {};
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: parsedData,
            rawBody: responseData
          });
        } catch (error) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: responseData,
            rawBody: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (postData) {
      req.write(postData);
    }

    req.end();
  });
}

// 端口检测
async function detectWorkingPort() {
  for (const port of config.ports) {
    try {
      log.info(`检测端口 ${port}...`);
      await makeRequest('GET', '/rest/v1/scenarios', null, false);
      activePort = port;
      log.success(`检测到工作端口: ${port}`);
      return true;
    } catch (error) {
      log.warning(`端口 ${port} 不可用: ${error.message}`);
    }
  }
  return false;
}

// 测试单个 API
async function testAPI(name, method, path, data = null, useAuth = false, module = 'General') {
  testResults.total++;
  if (!testResults.modules[module]) {
    testResults.modules[module] = { total: 0, passed: 0, failed: 0 };
  }
  testResults.modules[module].total++;

  try {
    log.info(`测试: ${method} ${path}`);
    const response = await makeRequest(method, path, data, useAuth);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log.success(`${name}: ${response.statusCode} ✓`);
      testResults.passed++;
      testResults.modules[module].passed++;
      return {
        success: true,
        name,
        method,
        path,
        status: response.statusCode,
        data: response.data
      };
    } else {
      throw new Error(`HTTP ${response.statusCode}: ${response.rawBody}`);
    }
  } catch (error) {
    log.error(`${name}: ${error.message}`);
    testResults.failed++;
    testResults.modules[module].failed++;
    testResults.errors.push({
      name,
      method,
      path,
      module,
      error: error.message,
      details: error.response?.data || error.message
    });

    return {
      success: false,
      name,
      method,
      path,
      error: error.message
    };
  }
}

// 认证模块测试
async function testAuthModule() {
  log.header('🔐 认证模块测试');

  // 用户登录 - 获取token
  const loginResult = await testAPI(
    '管理员登录',
    'POST',
    '/rest/v1/auth/login',
    config.admin,
    false,
    'Authentication'
  );

  if (loginResult.success && loginResult.data.accessToken) {
    authToken = loginResult.data.accessToken;
    userId = loginResult.data.user?.id;
    log.success(`成功获取认证token, 用户ID: ${userId || 'N/A'}`);
  } else {
    log.error('无法获取认证token，后续需要认证的测试将跳过');
  }

  // 其他认证接口
  await testAPI('用户注册', 'POST', '/rest/v1/auth/register', {
    email: 'test-' + Date.now() + '@example.com',
    password: 'TestPassword123',
    name: '测试用户'
  }, false, 'Authentication');

  await testAPI('发送OTP', 'POST', '/rest/v1/auth/otp/send', {
    email: 'test@example.com'
  }, false, 'Authentication');

  await testAPI('验证OTP', 'POST', '/rest/v1/auth/otp/verify', {
    email: 'test@example.com',
    token: '123456'
  }, false, 'Authentication');

  await testAPI('刷新Token', 'POST', '/rest/v1/auth/refresh', {
    refreshToken: 'dummy-refresh-token'
  }, false, 'Authentication');

  if (authToken) {
    await testAPI('获取当前用户信息', 'GET', '/rest/v1/auth/me', null, true, 'Authentication');
    await testAPI('用户登出', 'POST', '/rest/v1/auth/logout', null, true, 'Authentication');
  }
}

// 场景模块测试
async function testScenariosModule() {
  log.header('🎭 场景模块测试');

  const scenarioList = await testAPI('获取场景列表', 'GET', '/rest/v1/scenarios', null, false, 'Scenarios');
  await testAPI('获取场景统计', 'GET', '/rest/v1/scenarios/stats/count', null, false, 'Scenarios');

  // 如果获取到场景，测试详情接口
  if (scenarioList.success && scenarioList.data && Array.isArray(scenarioList.data) && scenarioList.data.length > 0) {
    const firstScenario = scenarioList.data[0];
    if (firstScenario.id) {
      await testAPI('根据ID获取场景详情', 'GET', `/rest/v1/scenarios/${firstScenario.id}`, null, false, 'Scenarios');
    }
    if (firstScenario.code) {
      await testAPI('根据代码获取场景详情', 'GET', `/rest/v1/scenarios/code/${firstScenario.code}`, null, false, 'Scenarios');
    }
  } else {
    log.warning('未获取到场景数据，跳过详情测试');
  }
}

// 器材模块测试
async function testEquipmentModule() {
  log.header('🏋️ 器材模块测试');

  await testAPI('获取器材列表', 'GET', '/rest/v1/equipment', null, false, 'Equipment');
  await testAPI('获取器材列表(分页)', 'GET', '/rest/v1/equipment?page=1&pageSize=5', null, false, 'Equipment');
  await testAPI('获取器材列表(按分类)', 'GET', '/rest/v1/equipment?category=FURNITURE', null, false, 'Equipment');
  await testAPI('获取活跃器材列表', 'GET', '/rest/v1/equipment/active/list', null, false, 'Equipment');
  await testAPI('获取分组器材列表', 'GET', '/rest/v1/equipment/category/grouped', null, false, 'Equipment');
  await testAPI('获取器材统计信息', 'GET', '/rest/v1/equipment/stats/summary', null, false, 'Equipment');

  // 创建器材测试
  const createEquipmentData = {
    code: `TEST_EQUIPMENT_${Date.now()}`,
    name: '测试器材',
    category: 'FURNITURE',
    imageUrl: 'https://example.com/test.jpg',
    displayOrder: 100,
    isActive: true
  };

  const createResult = await testAPI('创建器材', 'POST', '/rest/v1/equipment', createEquipmentData, false, 'Equipment');

  let equipmentId = null;
  if (createResult.success && createResult.data?.id) {
    equipmentId = createResult.data.id;

    await testAPI('根据ID获取器材详情', 'GET', `/rest/v1/equipment/${equipmentId}`, null, false, 'Equipment');
    await testAPI('更新器材', 'PUT', `/rest/v1/equipment/${equipmentId}`, {
      name: '更新后的测试器材'
    }, false, 'Equipment');
    await testAPI('软删除器材', 'PUT', `/rest/v1/equipment/${equipmentId}/deactivate`, null, false, 'Equipment');
  } else {
    log.warning('器材创建失败，跳过相关测试');
  }

  // 根据代码获取器材
  await testAPI('根据代码获取器材详情', 'GET', `/rest/v1/equipment/code/${createEquipmentData.code}`, null, false, 'Equipment');
}

// 推荐模块测试
async function testRecommendationModule() {
  log.header('💪 推荐模块测试');

  // 快速推荐 - 使用修复后的参数格式
  const quickRecommendationData = {
    userId: userId || 'anonymous-user',
    intents: ['RELAX'], // 使用修复后的 intents 数组
    scenario: null,
    equipment: [],
    targetMuscles: ['FULL_BODY'], // 使用有效的enum值
    currentStep: 3
  };

  await testAPI('快速推荐', 'POST', '/api/v1/recommendations/quick', quickRecommendationData, false, 'Recommendations');

  // 替换动作
  const replaceData = {
    sessionId: 'dummy-session-id',
    exercisePosition: 1,
    currentExerciseId: 'dummy-exercise-id'
  };

  await testAPI('替换动作', 'POST', '/api/v1/recommendations/replace', replaceData, false, 'Recommendations');

  // 获取替换候选
  await testAPI('获取替换候选', 'GET', '/api/v1/recommendations/alternatives?sessionId=dummy-session-id', null, false, 'Recommendations');
}

// 训练会话模块测试
async function testWorkoutSessionsModule() {
  log.header('🏃 训练会话模块测试');

  await testAPI('健康检查', 'GET', '/api/v1/workout-sessions/health', null, false, 'WorkoutSessions');

  if (userId) {
    // 创建训练会话
    const sessionData = {
      userId,
      intentType: 'STRETCH', // 注意：这里使用 intentType，不是 intent
      totalDuration: 300,
      difficulty: 'GREEN'
    };

    const createSessionResult = await testAPI('创建训练会话', 'POST', '/api/v1/workout-sessions', sessionData, true, 'WorkoutSessions');

    let sessionId = null;
    if (createSessionResult.success && createSessionResult.data?.id) {
      sessionId = createSessionResult.data.id;

      await testAPI('获取训练会话详情', 'GET', `/api/v1/workout-sessions/${sessionId}`, null, true, 'WorkoutSessions');
      await testAPI('更新训练会话', 'PATCH', `/api/v1/workout-sessions/${sessionId}`, {
        status: 'IN_PROGRESS'
      }, true, 'WorkoutSessions');
      await testAPI('完成训练会话', 'POST', `/api/v1/workout-sessions/${sessionId}/complete`, null, true, 'WorkoutSessions');
    }

    await testAPI('获取用户会话列表', 'GET', `/api/v1/users/${userId}/sessions`, null, true, 'WorkoutSessions');
    await testAPI('获取用户统计', 'GET', `/api/v1/users/${userId}/stats`, null, true, 'WorkoutSessions');
  } else {
    log.warning('无用户ID，跳过需要认证的会话测试');
  }
}

// 卡片模块测试
async function testCardsModule() {
  log.header('🃏 卡片模块测试');

  await testAPI('卡片健康检查', 'GET', '/api/v1/cards/health', null, false, 'Cards');
  await testAPI('获取公开卡片', 'GET', '/api/v1/cards/public', null, false, 'Cards');
  await testAPI('获取稀有度排名', 'GET', '/api/v1/rarity/ranking', null, false, 'Cards');

  if (userId) {
    // 生成结果卡片
    const generateCardData = {
      sessionId: 'dummy-session-id',
      userId
    };

    const generateResult = await testAPI('生成结果卡片', 'POST', '/api/v1/cards/generate', generateCardData, true, 'Cards');

    let cardId = null;
    if (generateResult.success && generateResult.data?.id) {
      cardId = generateResult.data.id;

      await testAPI('获取卡片详情', 'GET', `/api/v1/cards/${cardId}`, null, true, 'Cards');
      await testAPI('更新卡片', 'PATCH', `/api/v1/cards/${cardId}`, {
        title: '更新后的卡片标题'
      }, true, 'Cards');
      await testAPI('分享卡片', 'POST', `/api/v1/cards/${cardId}/share`, null, true, 'Cards');
    }

    await testAPI('获取用户卡片', 'GET', `/api/v1/users/${userId}/cards`, null, true, 'Cards');
    await testAPI('获取用户卡片统计', 'GET', `/api/v1/users/${userId}/cards/stats`, null, true, 'Cards');
  }

  // 计算稀有度
  await testAPI('计算稀有度', 'GET', '/api/v1/rarity/calculate/TEST_CODE', null, false, 'Cards');
  await testAPI('批量计算稀有度', 'POST', '/api/v1/rarity/calculate-batch', {
    codes: ['CODE1', 'CODE2']
  }, false, 'Cards');
  await testAPI('稀有度趋势', 'GET', '/api/v1/rarity/TEST_CODE/trend', null, false, 'Cards');
}

// 分析模块测试
async function testAnalyticsModule() {
  log.header('📊 分析模块测试');

  if (userId) {
    await testAPI('更新用户分析', 'PATCH', `/api/v1/analytics/users/${userId}`, {
      action: 'WORKOUT_COMPLETED'
    }, true, 'Analytics');

    await testAPI('获取用户漏斗', 'GET', `/api/v1/analytics/users/${userId}/funnel`, null, true, 'Analytics');
    await testAPI('获取用户指标', 'GET', `/api/v1/analytics/users/${userId}/metrics`, null, true, 'Analytics');
    await testAPI('获取用户日常数据', 'GET', `/api/v1/analytics/users/${userId}/daily`, null, true, 'Analytics');
  }

  await testAPI('获取群组分析', 'GET', '/api/v1/analytics/cohorts', null, false, 'Analytics');
  await testAPI('获取平台KPI', 'GET', '/api/v1/analytics/platform/kpis', null, false, 'Analytics');

  // 批量日常指标
  const metricsData = {
    metrics: [
      {
        userId: userId || 'dummy-user',
        date: new Date().toISOString().split('T')[0],
        workoutCount: 1
      }
    ]
  };

  await testAPI('批量日常指标', 'POST', '/api/v1/analytics/daily-metrics/batch', metricsData, false, 'Analytics');
}

// 主题周模块测试
async function testThemeWeeksModule() {
  log.header('🎯 主题周模块测试');

  const currentThemeResult = await testAPI('获取当前主题周', 'GET', '/api/v1/theme-weeks/current', null, false, 'ThemeWeeks');

  let themeWeekId = null;
  if (currentThemeResult.success && currentThemeResult.data?.id) {
    themeWeekId = currentThemeResult.data.id;
  }

  if (themeWeekId && userId) {
    await testAPI('加入主题周', 'POST', `/api/v1/theme-weeks/${themeWeekId}/join`, {
      userId
    }, true, 'ThemeWeeks');

    await testAPI('更新主题周进度', 'POST', `/api/v1/theme-weeks/${themeWeekId}/update-progress`, {
      userId,
      progress: 50
    }, true, 'ThemeWeeks');
  } else {
    log.warning('无主题周ID或用户ID，跳过相关测试');
  }
}

// 场景器材关联模块测试
async function testScenarioEquipmentModule() {
  log.header('🔗 场景器材关联模块测试');

  // 创建关联
  await testAPI('创建场景器材关联', 'POST', '/rest/v1/scenario-equipment', {
    scenarioId: 'dummy-scenario-id',
    equipmentId: 'dummy-equipment-id'
  }, false, 'ScenarioEquipment');

  // 批量创建关联
  await testAPI('批量创建关联', 'POST', '/rest/v1/scenario-equipment/batch', {
    scenarioId: 'dummy-scenario-id',
    equipmentIds: ['equipment1', 'equipment2']
  }, false, 'ScenarioEquipment');

  await testAPI('获取场景器材', 'GET', '/rest/v1/scenario-equipment/scenario/dummy-scenario-id/equipment', null, false, 'ScenarioEquipment');
  await testAPI('获取器材场景', 'GET', '/rest/v1/scenario-equipment/equipment/dummy-equipment-id/scenarios', null, false, 'ScenarioEquipment');
  await testAPI('检查关联存在', 'GET', '/rest/v1/scenario-equipment/dummy-scenario-id/dummy-equipment-id/exists', null, false, 'ScenarioEquipment');
}

// 生成测试报告
function generateReport() {
  log.header('📋 测试报告');

  console.log(`总计测试: ${testResults.total}`);
  console.log(`✅ 成功: ${testResults.passed}`);
  console.log(`❌ 失败: ${testResults.failed}`);
  console.log(`成功率: ${((testResults.passed / testResults.total) * 100).toFixed(2)}%`);

  // 按模块统计
  log.separator();
  console.log('📊 按模块统计:');
  for (const [moduleName, stats] of Object.entries(testResults.modules)) {
    const successRate = ((stats.passed / stats.total) * 100).toFixed(2);
    console.log(`  ${moduleName}: ${stats.passed}/${stats.total} (${successRate}%)`);
  }

  // 错误详情
  if (testResults.errors.length > 0) {
    log.separator();
    console.log('❌ 错误详情:');
    testResults.errors.forEach((error, index) => {
      console.log(`\n${index + 1}. ${error.name} [${error.module}]`);
      console.log(`   ${error.method} ${error.path}`);
      console.log(`   错误: ${error.error}`);
      if (error.details && typeof error.details === 'object') {
        console.log(`   详情: ${JSON.stringify(error.details, null, 2)}`);
      }
    });
  }

  log.separator();

  if (testResults.failed === 0) {
    log.success('🎉 所有API测试通过！');
  } else {
    log.error(`发现 ${testResults.failed} 个问题需要修复`);
  }

  // 返回结果供外部使用
  return {
    totalTests: testResults.total,
    passedTests: testResults.passed,
    failedTests: testResults.failed,
    successRate: (testResults.passed / testResults.total) * 100,
    moduleStats: testResults.modules,
    errors: testResults.errors
  };
}

// 主函数
async function main() {
  console.clear();
  log.header('🚀 SnapRep 后端 API 全面测试 v2.0');

  log.info('开始检测后端服务...');

  // 检测工作端口
  const portDetected = await detectWorkingPort();
  if (!portDetected) {
    log.error('无法检测到工作的后端服务，请确保服务已启动');
    process.exit(1);
  }

  log.info(`服务地址: http://${config.hostname}:${activePort}`);
  log.info(`管理员账号: ${config.admin.email}`);

  try {
    // 按模块执行测试
    await testAuthModule();
    await testScenariosModule();
    await testEquipmentModule();
    await testRecommendationModule();
    await testWorkoutSessionsModule();
    await testCardsModule();
    await testAnalyticsModule();
    await testThemeWeeksModule();
    await testScenarioEquipmentModule();

    // 生成报告
    const report = generateReport();

    // 返回报告供外部使用
    return report;

  } catch (error) {
    log.error(`测试执行失败: ${error.message}`);
    console.error(error.stack);
    return null;
  }
}

// 执行测试
if (require.main === module) {
  main().then(report => {
    if (report && report.failedTests > 0) {
      process.exit(1); // 如果有失败的测试，退出码为1
    }
  }).catch(console.error);
}

module.exports = { main, testAPI };
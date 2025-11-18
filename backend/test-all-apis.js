#!/usr/bin/env node

/**
 * SnapRep 后端 API 全面测试脚本
 *
 * 功能：
 * - 自动登录获取token
 * - 测试所有75+个API端点
 * - 生成详细的成功/失败报告
 * - 分类测试各个模块
 * - 彩色控制台输出
 *
 * 使用方法：
 * node test-all-apis.js
 */

const axios = require('axios');
const colors = require('colors');

// 配置
const config = {
  baseURL: 'http://localhost:3000',
  admin: {
    email: 'admin@snaprep.com',
    password: 'Linlin@123'
  }
};

// 全局变量
let authToken = null;
let userId = null;
const testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: []
};

// 工具函数：彩色输出
const log = {
  info: (msg) => console.log('ℹ️ '.blue + msg),
  success: (msg) => console.log('✅ '.green + msg.green),
  error: (msg) => console.log('❌ '.red + msg.red),
  warning: (msg) => console.log('⚠️ '.yellow + msg.yellow),
  header: (msg) => console.log('\n' + '='.repeat(60).cyan + '\n' + msg.cyan.bold + '\n' + '='.repeat(60).cyan),
  separator: () => console.log('-'.repeat(60).gray)
};

// HTTP客户端设置
const client = axios.create({
  baseURL: config.baseURL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 测试单个API接口
async function testAPI(name, method, url, data = null, auth = false) {
  testResults.total++;

  try {
    const requestConfig = {
      method,
      url,
      ...(data && { data }),
      ...(auth && authToken && {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      })
    };

    log.info(`Testing ${method} ${url}`);
    const response = await client(requestConfig);

    log.success(`${name}: ${response.status} - ${response.statusText}`);
    testResults.passed++;

    return {
      success: true,
      name,
      method,
      url,
      status: response.status,
      data: response.data
    };

  } catch (error) {
    const errorMsg = error.response
      ? `${error.response.status} - ${error.response.statusText}: ${JSON.stringify(error.response.data)}`
      : error.message;

    log.error(`${name}: ${errorMsg}`);
    testResults.failed++;
    testResults.errors.push({
      name,
      method,
      url,
      error: errorMsg,
      details: error.response?.data || error.message
    });

    return {
      success: false,
      name,
      method,
      url,
      error: errorMsg
    };
  }
}

// 1. 认证模块测试
async function testAuthModule() {
  log.header('🔐 认证模块测试');

  // 用户登录 - 获取token
  const loginResult = await testAPI(
    '用户登录',
    'POST',
    '/rest/v1/auth/login',
    config.admin
  );

  if (loginResult.success && loginResult.data.accessToken) {
    authToken = loginResult.data.accessToken;
    userId = loginResult.data.user.id;
    log.success(`成功获取认证token, 用户ID: ${userId}`);
  } else {
    log.error('无法获取认证token，后续需要认证的测试将跳过');
  }

  // 其他认证接口
  await testAPI('用户注册', 'POST', '/rest/v1/auth/register', {
    email: 'test@example.com',
    password: 'TestPassword123',
    name: '测试用户'
  });

  await testAPI('发送OTP', 'POST', '/rest/v1/auth/otp/send', {
    email: 'test@example.com'
  });

  await testAPI('验证OTP', 'POST', '/rest/v1/auth/otp/verify', {
    email: 'test@example.com',
    token: '123456'
  });

  await testAPI('刷新Token', 'POST', '/rest/v1/auth/refresh', {
    refreshToken: 'dummy-refresh-token'
  });

  if (authToken) {
    await testAPI('获取当前用户信息', 'GET', '/rest/v1/auth/me', null, true);
    await testAPI('用户登出', 'POST', '/rest/v1/auth/logout', null, true);
  }
}

// 2. 场景模块测试
async function testScenariosModule() {
  log.header('🎭 场景模块测试');

  await testAPI('获取场景列表', 'GET', '/rest/v1/scenarios');
  await testAPI('获取场景统计', 'GET', '/rest/v1/scenarios/stats/count');

  // 先获取场景列表以获得有效的ID和code
  try {
    const response = await client.get('/rest/v1/scenarios');
    if (response.data && response.data.length > 0) {
      const firstScenario = response.data[0];
      await testAPI('根据ID获取场景详情', 'GET', `/rest/v1/scenarios/${firstScenario.id}`);
      await testAPI('根据代码获取场景详情', 'GET', `/rest/v1/scenarios/code/${firstScenario.code}`);
    }
  } catch (error) {
    log.warning('无法获取场景数据，跳过详情测试');
  }
}

// 3. 器材模块测试
async function testEquipmentModule() {
  log.header('🏋️ 器材模块测试');

  await testAPI('获取器材列表', 'GET', '/rest/v1/equipment');
  await testAPI('获取器材列表(分页)', 'GET', '/rest/v1/equipment?page=1&pageSize=5');
  await testAPI('获取器材列表(按分类)', 'GET', '/rest/v1/equipment?category=FURNITURE');
  await testAPI('获取活跃器材列表', 'GET', '/rest/v1/equipment/active/list');
  await testAPI('获取分组器材列表', 'GET', '/rest/v1/equipment/category/grouped');
  await testAPI('获取器材统计信息', 'GET', '/rest/v1/equipment/stats/summary');

  // 创建器材测试
  const createEquipmentData = {
    code: 'TEST_EQUIPMENT_001',
    name: '测试器材',
    category: 'FURNITURE',
    imageUrl: 'https://example.com/test.jpg',
    displayOrder: 100,
    isActive: true
  };

  const createResult = await testAPI('创建器材', 'POST', '/rest/v1/equipment', createEquipmentData);

  let equipmentId = null;
  if (createResult.success && createResult.data.id) {
    equipmentId = createResult.data.id;
  } else {
    // 尝试获取现有器材ID
    try {
      const response = await client.get('/rest/v1/equipment?pageSize=1');
      if (response.data && response.data.data && response.data.data.length > 0) {
        equipmentId = response.data.data[0].id;
      }
    } catch (error) {
      log.warning('无法获取器材ID，跳过相关测试');
    }
  }

  if (equipmentId) {
    await testAPI('根据ID获取器材详情', 'GET', `/rest/v1/equipment/${equipmentId}`);
    await testAPI('更新器材', 'PUT', `/rest/v1/equipment/${equipmentId}`, {
      name: '更新后的测试器材'
    });
    await testAPI('软删除器材', 'PUT', `/rest/v1/equipment/${equipmentId}/deactivate`);
  }

  // 批量更新状态测试
  if (equipmentId) {
    await testAPI('批量更新器材状态', 'PUT', '/rest/v1/equipment/batch/status', {
      ids: [equipmentId],
      isActive: true
    });
  }

  // 根据代码获取器材
  await testAPI('根据代码获取器材详情', 'GET', '/rest/v1/equipment/code/TEST_EQUIPMENT_001');
}

// 4. 推荐模块测试
async function testRecommendationModule() {
  log.header('💪 推荐模块测试');

  // 快速推荐 - 修复参数格式
  const quickRecommendationData = {
    userId: userId || 'anonymous-user',
    intents: ['RELAX'],
    scenario: null,
    equipment: [],
    targetMuscles: ['FULL_BODY'], // 修复：只使用一个有效的enum值
    currentStep: 3
  };

  await testAPI('快速推荐', 'POST', '/api/v1/recommendations/quick', quickRecommendationData);

  // 替换动作
  const replaceData = {
    sessionId: 'dummy-session-id',
    exercisePosition: 0,
    adjustment: 'EASIER'
  };

  await testAPI('替换动作', 'POST', '/api/v1/recommendations/replace', replaceData);

  // 获取替换候选
  await testAPI('获取替换候选', 'GET', '/api/v1/recommendations/alternatives?sessionId=dummy-session-id');
}

// 5. 训练会话模块测试
async function testWorkoutSessionsModule() {
  log.header('🏃 训练会话模块测试');

  await testAPI('健康检查', 'GET', '/api/v1/workout-sessions/health');

  if (userId) {
    // 创建训练会话
    const sessionData = {
      userId,
      intentType: 'STRETCH',
      totalDuration: 300,
      difficulty: 'GREEN'
    };

    const createSessionResult = await testAPI('创建训练会话', 'POST', '/api/v1/workout-sessions', sessionData, true);

    let sessionId = null;
    if (createSessionResult.success && createSessionResult.data.id) {
      sessionId = createSessionResult.data.id;
    }

    if (sessionId) {
      await testAPI('获取训练会话详情', 'GET', `/api/v1/workout-sessions/${sessionId}`, null, true);
      await testAPI('更新训练会话', 'PATCH', `/api/v1/workout-sessions/${sessionId}`, {
        status: 'IN_PROGRESS'
      }, true);
      await testAPI('完成训练会话', 'POST', `/api/v1/workout-sessions/${sessionId}/complete`, null, true);
    }

    await testAPI('获取用户会话列表', 'GET', `/api/v1/users/${userId}/sessions`, null, true);
    await testAPI('获取用户统计', 'GET', `/api/v1/users/${userId}/stats`, null, true);
  }

  // 从推荐创建会话
  const recommendationSessionData = {
    recommendationId: 'dummy-recommendation-id',
    userId: userId || 'anonymous-user'
  };

  await testAPI('从推荐创建会话', 'POST', '/api/v1/workout-sessions/from-recommendation', recommendationSessionData, !!userId);
}

// 6. 卡片模块测试
async function testCardsModule() {
  log.header('🃏 卡片模块测试');

  await testAPI('卡片健康检查', 'GET', '/api/v1/cards/health');
  await testAPI('获取公开卡片', 'GET', '/api/v1/cards/public');
  await testAPI('获取稀有度排名', 'GET', '/api/v1/rarity/ranking');

  if (userId) {
    // 生成结果卡片
    const generateCardData = {
      sessionId: 'dummy-session-id',
      userId
    };

    const generateResult = await testAPI('生成结果卡片', 'POST', '/api/v1/cards/generate', generateCardData, true);

    let cardId = null;
    if (generateResult.success && generateResult.data.id) {
      cardId = generateResult.data.id;
    }

    if (cardId) {
      await testAPI('获取卡片详情', 'GET', `/api/v1/cards/${cardId}`, null, true);
      await testAPI('更新卡片', 'PATCH', `/api/v1/cards/${cardId}`, {
        title: '更新后的卡片标题'
      }, true);
      await testAPI('分享卡片', 'POST', `/api/v1/cards/${cardId}/share`, null, true);
    }

    await testAPI('获取用户卡片', 'GET', `/api/v1/users/${userId}/cards`, null, true);
    await testAPI('获取用户卡片统计', 'GET', `/api/v1/users/${userId}/cards/stats`, null, true);
  }

  // 计算稀有度
  await testAPI('计算稀有度', 'GET', '/api/v1/rarity/calculate/TEST_CODE');
  await testAPI('批量计算稀有度', 'POST', '/api/v1/rarity/calculate-batch', {
    codes: ['CODE1', 'CODE2']
  });
  await testAPI('稀有度趋势', 'GET', '/api/v1/rarity/TEST_CODE/trend');
}

// 7. 分析模块测试
async function testAnalyticsModule() {
  log.header('📊 分析模块测试');

  if (userId) {
    await testAPI('更新用户分析', 'PATCH', `/api/v1/analytics/users/${userId}`, {
      action: 'WORKOUT_COMPLETED'
    }, true);

    await testAPI('获取用户漏斗', 'GET', `/api/v1/analytics/users/${userId}/funnel`, null, true);
    await testAPI('获取用户指标', 'GET', `/api/v1/analytics/users/${userId}/metrics`, null, true);
    await testAPI('获取用户日常数据', 'GET', `/api/v1/analytics/users/${userId}/daily`, null, true);
  }

  await testAPI('获取群组分析', 'GET', '/api/v1/analytics/cohorts');
  await testAPI('获取平台KPI', 'GET', '/api/v1/analytics/platform/kpis');

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

  await testAPI('批量日常指标', 'POST', '/api/v1/analytics/daily-metrics/batch', metricsData);
}

// 8. 主题周模块测试
async function testThemeWeeksModule() {
  log.header('🎯 主题周模块测试');

  const currentThemeResult = await testAPI('获取当前主题周', 'GET', '/api/v1/theme-weeks/current');

  let themeWeekId = null;
  if (currentThemeResult.success && currentThemeResult.data.id) {
    themeWeekId = currentThemeResult.data.id;
  }

  if (themeWeekId && userId) {
    await testAPI('加入主题周', 'POST', `/api/v1/theme-weeks/${themeWeekId}/join`, {
      userId
    }, true);

    await testAPI('更新主题周进度', 'POST', `/api/v1/theme-weeks/${themeWeekId}/update-progress`, {
      userId,
      progress: 50
    }, true);
  }
}

// 9. 场景器材关联模块测试
async function testScenarioEquipmentModule() {
  log.header('🔗 场景器材关联模块测试');

  // 创建关联
  await testAPI('创建场景器材关联', 'POST', '/rest/v1/scenario-equipment', {
    scenarioId: 'dummy-scenario-id',
    equipmentId: 'dummy-equipment-id'
  });

  // 批量创建关联
  await testAPI('批量创建关联', 'POST', '/rest/v1/scenario-equipment/batch', {
    scenarioId: 'dummy-scenario-id',
    equipmentIds: ['equipment1', 'equipment2']
  });

  await testAPI('获取场景器材', 'GET', '/rest/v1/scenario-equipment/scenario/dummy-scenario-id/equipment');
  await testAPI('获取器材场景', 'GET', '/rest/v1/scenario-equipment/equipment/dummy-equipment-id/scenarios');
  await testAPI('检查关联存在', 'GET', '/rest/v1/scenario-equipment/dummy-scenario-id/dummy-equipment-id/exists');
}

// 生成测试报告
function generateReport() {
  log.header('📋 测试报告');

  console.log(`总计测试: ${testResults.total}`.bold);
  console.log(`✅ 成功: ${testResults.passed}`.green);
  console.log(`❌ 失败: ${testResults.failed}`.red);
  console.log(`成功率: ${((testResults.passed / testResults.total) * 100).toFixed(2)}%`);

  if (testResults.errors.length > 0) {
    log.header('❌ 错误详情');
    testResults.errors.forEach((error, index) => {
      console.log(`\n${index + 1}. ${error.name}`.red.bold);
      console.log(`   ${error.method} ${error.url}`.gray);
      console.log(`   错误: ${error.error}`.red);
      if (error.details && typeof error.details === 'object') {
        console.log(`   详情: ${JSON.stringify(error.details, null, 2)}`.gray);
      }
    });
  }

  log.separator();

  if (testResults.failed === 0) {
    log.success('🎉 所有API测试通过！');
  } else {
    log.error(`发现 ${testResults.failed} 个问题需要修复`);
  }
}

// 主函数
async function main() {
  console.clear();
  log.header('🚀 SnapRep 后端 API 全面测试');

  log.info('开始测试后端服务...');
  log.info(`服务地址: ${config.baseURL}`);
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
    generateReport();

  } catch (error) {
    log.error(`测试执行失败: ${error.message}`);
    console.error(error.stack);
  }
}

// 执行测试
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testAPI, main };
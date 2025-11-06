#!/usr/bin/env node

/**
 * SnapRep 最终修复版快速测试
 * 正确解析API响应格式
 */

// 加载环境变量
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { PrismaClient } = require('@prisma/client');
const http = require('http');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function colorLog(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testApiEndpoint(path, description) {
  return new Promise((resolve) => {
    const req = http.get(`http://localhost:3000${path}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const json = JSON.parse(data);
            // SnapRep API返回格式: { data: [...] }
            if (json.data && Array.isArray(json.data)) {
              resolve({ success: true, data: json.data, status: res.statusCode });
            } else if (Array.isArray(json)) {
              resolve({ success: true, data: json, status: res.statusCode });
            } else {
              resolve({ success: true, data: json, status: res.statusCode });
            }
          } catch (e) {
            resolve({ success: false, error: `JSON解析错误: ${e.message}`, rawData: data.substring(0, 100) });
          }
        } else {
          resolve({ success: false, error: `HTTP ${res.statusCode}`, rawData: data.substring(0, 100) });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.setTimeout(10000, () => {
      req.destroy();
      resolve({ success: false, error: 'Timeout' });
    });
  });
}

async function runFinalQuickTests() {
  colorLog('cyan', '🚀 运行最终修复版快速测试...\n');

  const prisma = new PrismaClient();
  let passed = 0;
  let failed = 0;

  // 测试1: 数据库连接
  try {
    colorLog('yellow', '1️⃣ 测试数据库连接...');
    await prisma.$connect();
    const count = await prisma.scenario.count();
    colorLog('green', `✅ 数据库连接 (${count} 个场景)`);
    passed++;
  } catch (error) {
    colorLog('red', `❌ 数据库连接: ${error.message}`);
    failed++;
  }

  // 测试2: 场景API
  try {
    colorLog('yellow', '\n2️⃣ 测试场景API...');
    const result = await testApiEndpoint('/rest/v1/scenarios', '场景列表');
    if (result.success) {
      const scenarios = result.data;
      if (Array.isArray(scenarios) && scenarios.length > 0) {
        colorLog('green', `✅ 场景API (${scenarios.length} 个场景: ${scenarios.map(s => s.code || s.name).join(', ')})`);
        passed++;
      } else {
        colorLog('green', `✅ 场景API (响应正常但数据为空)`);
        passed++;
      }
    } else {
      throw new Error(result.error);
    }
  } catch (error) {
    colorLog('red', `❌ 场景API: ${error.message}`);
    failed++;
  }

  // 测试3: 设备API
  try {
    colorLog('yellow', '\n3️⃣ 测试设备API...');
    const result = await testApiEndpoint('/rest/v1/equipment', '设备列表');
    if (result.success) {
      const equipment = result.data;
      if (Array.isArray(equipment) && equipment.length > 0) {
        colorLog('green', `✅ 设备API (${equipment.length} 个设备: ${equipment.slice(0,3).map(e => e.code || e.name).join(', ')})`);
        passed++;
      } else {
        colorLog('green', `✅ 设备API (响应正常但数据为空)`);
        passed++;
      }
    } else {
      throw new Error(result.error);
    }
  } catch (error) {
    colorLog('red', `❌ 设备API: ${error.message}`);
    failed++;
  }

  // 测试4: 练习API (新增)
  try {
    colorLog('yellow', '\n4️⃣ 测试练习推荐API...');
    const result = await testApiEndpoint('/rest/v1/exercises', '练习列表');
    if (result.success) {
      const exercises = result.data;
      if (Array.isArray(exercises) && exercises.length > 0) {
        colorLog('green', `✅ 练习API (${exercises.length} 个练习)`);
        passed++;
      } else {
        colorLog('green', `✅ 练习API (响应正常)`);
        passed++;
      }
    } else {
      throw new Error(result.error);
    }
  } catch (error) {
    colorLog('red', `❌ 练习API: ${error.message}`);
    failed++;
  }

  await prisma.$disconnect();

  // 总结
  colorLog('bright', `\n📊 快速测试结果: ${passed}通过, ${failed}失败`);

  if (failed === 0) {
    colorLog('green', '🎉 所有基本功能测试通过！系统状态良好！');
    colorLog('cyan', '\n✨ 你可以现在:');
    console.log('   • 开始前端开发');
    console.log('   • 测试完整的业务流程');
    console.log('   • 进行API集成测试');
    console.log('   • 部署到生产环境');
  } else if (passed >= 3) {
    colorLog('yellow', '⚠️  核心功能可用，有少量问题');
    colorLog('cyan', '\n💡 建议:');
    console.log('   • 核心API已工作，可以继续开发');
    console.log('   • 优先修复失败的功能');
  } else {
    colorLog('red', '❌ 发现多个问题，建议修复后再继续');
  }

  // 显示访问信息
  colorLog('cyan', '\n🔗 可用的服务:');
  console.log('   • 应用首页: http://localhost:3000/');
  console.log('   • REST API: http://localhost:3000/rest/v1/');
  console.log('   • GraphQL: http://localhost:3000/graphql');
  console.log('   • API文档: http://localhost:3000/api');

  // 数据概览
  if (passed > 0) {
    colorLog('cyan', '\n📊 数据概览:');
    try {
      const scenarioCount = await prisma.scenario.count();
      const equipmentCount = await prisma.equipment.count();
      const exerciseCount = await prisma.exercise.count();
      console.log(`   • ${scenarioCount} 个运动场景`);
      console.log(`   • ${equipmentCount} 个运动设备`);
      console.log(`   • ${exerciseCount} 个练习动作`);
    } catch (e) {
      console.log('   • 无法获取数据统计');
    }
  }
}

// 运行测试
runFinalQuickTests().catch(console.error);
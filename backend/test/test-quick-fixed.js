#!/usr/bin/env node

/**
 * SnapRep 修复版快速测试
 * 解决schema不匹配和Jest配置问题
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
            resolve({ success: true, data: json, status: res.statusCode });
          } catch (e) {
            resolve({ success: true, data: data, status: res.statusCode });
          }
        } else {
          resolve({ success: false, error: `HTTP ${res.statusCode}`, data });
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

async function runFixedQuickTests() {
  colorLog('cyan', '🚀 运行修复版快速冒烟测试...\n');

  const prisma = new PrismaClient();
  let passed = 0;
  let failed = 0;

  // 测试1: 数据库连接
  try {
    colorLog('yellow', '1️⃣ 测试数据库连接...');
    await prisma.$connect();
    await prisma.scenario.count();
    colorLog('green', '✅ 数据库连接');
    passed++;
  } catch (error) {
    colorLog('red', '❌ 数据库连接');
    failed++;
  }

  // 测试2: 场景API
  try {
    colorLog('yellow', '\n2️⃣ 测试场景API...');
    const result = await testApiEndpoint('/rest/v1/scenarios', '场景列表');
    if (result.success && Array.isArray(result.data)) {
      colorLog('green', `✅ 场景API (返回 ${result.data.length} 个场景)`);
      passed++;
    } else {
      throw new Error(result.error || 'API响应格式错误');
    }
  } catch (error) {
    colorLog('red', '❌ 场景API');
    failed++;
  }

  // 测试3: 设备API
  try {
    colorLog('yellow', '\n3️⃣ 测试设备API...');
    const result = await testApiEndpoint('/rest/v1/equipment', '设备列表');
    if (result.success && Array.isArray(result.data)) {
      colorLog('green', `✅ 设备API (返回 ${result.data.length} 个设备)`);
      passed++;
    } else {
      throw new Error(result.error || 'API响应格式错误');
    }
  } catch (error) {
    colorLog('red', '❌ 设备API');
    failed++;
  }

  // 测试4: GraphQL API
  try {
    colorLog('yellow', '\n4️⃣ 测试GraphQL API...');
    const graphqlQuery = {
      query: `
        query {
          scenarios {
            id
            code
            name
            isActive
          }
        }
      `
    };

    const result = await new Promise((resolve) => {
      const postData = JSON.stringify(graphqlQuery);

      const options = {
        hostname: 'localhost',
        port: 3000,
        path: '/graphql',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const json = JSON.parse(data);
            if (json.data && json.data.scenarios) {
              resolve({ success: true, data: json.data });
            } else {
              resolve({ success: false, error: 'GraphQL错误', data: json });
            }
          } catch (e) {
            resolve({ success: false, error: 'JSON解析错误' });
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

      req.write(postData);
      req.end();
    });

    if (result.success) {
      colorLog('green', `✅ GraphQL API (查询到 ${result.data.scenarios.length} 个场景)`);
      passed++;
    } else {
      throw new Error(result.error);
    }
  } catch (error) {
    colorLog('red', '❌ GraphQL API');
    failed++;
  }

  await prisma.$disconnect();

  // 总结
  colorLog('bright', `\n📊 快速测试结果: ${passed}通过, ${failed}失败`);

  if (failed === 0) {
    colorLog('green', '🎉 系统状态良好，所有基本功能正常！');
    colorLog('cyan', '\n✨ 可以进行以下操作:');
    console.log('   • 继续开发新功能');
    console.log('   • 测试具体的业务流程');
    console.log('   • 运行完整的测试套件');
  } else if (passed >= 2) {
    colorLog('yellow', '⚠️  基本功能可用，但有部分问题需要修复');
    colorLog('cyan', '\n💡 建议:');
    console.log('   • 数据库和基本API已工作，可以继续开发');
    console.log('   • 稍后修复失败的API端点');
  } else {
    colorLog('red', '❌ 发现较多问题，建议先修复后再进行开发');
  }

  // 显示访问信息
  if (passed > 0) {
    colorLog('cyan', '\n🔗 可用的服务地址:');
    console.log('   • REST API: http://localhost:3000/rest/v1/');
    console.log('   • GraphQL: http://localhost:3000/graphql');
    console.log('   • API文档: http://localhost:3000/api');
  }
}

// 运行测试
runFixedQuickTests().catch(console.error);
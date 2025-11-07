#!/usr/bin/env node

/**
 * 测试快速推荐API修复结果
 * 验证ExercisesDao参数顺序修复后的功能
 */

const http = require('http');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function colorLog(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testQuickRecommendation() {
  colorLog('cyan', '🧪 测试快速推荐API修复结果...\n');

  const testCases = [
    {
      name: '基础测试 - 空手拉伸',
      payload: {
        intent: 'STRETCH',
        equipment: ['hands_free'],
        duration: 60
      }
    },
    {
      name: '办公室场景 - 椅子放松',
      payload: {
        intent: 'RELAX',
        equipment: ['chair'],
        duration: 120
      }
    },
    {
      name: '适度运动 - 多器材 (修正为MODERATE)',
      payload: {
        intent: 'MODERATE',
        equipment: ['hands_free', 'wall'],
        duration: 180
      }
    },
    {
      name: '力量训练测试',
      payload: {
        intent: 'STRENGTH',
        equipment: ['chair', 'wall'],
        duration: 240
      }
    }
  ];

  let passedTests = 0;
  let failedTests = 0;

  for (const testCase of testCases) {
    colorLog('yellow', `\n📋 测试: ${testCase.name}`);
    console.log(`请求参数: ${JSON.stringify(testCase.payload, null, 2)}`);

    try {
      const result = await makeRequest(testCase.payload);

      if (result.statusCode === 200) {
        colorLog('green', `✅ 测试通过 (${result.responseTime}ms)`);

        // 解析响应数据
        try {
          const data = JSON.parse(result.body);
          console.log(`返回动作数量: ${data.exercises?.length || 0}`);
          if (data.exercises && data.exercises.length > 0) {
            console.log(`示例动作: ${data.exercises[0].name || data.exercises[0].code}`);
          }
        } catch (e) {
          console.log('响应数据:', result.body.substring(0, 200));
        }

        passedTests++;
      } else if (result.statusCode === 404) {
        colorLog('yellow', `⚠️ 端点未找到 (HTTP ${result.statusCode})`);
        console.log('提示: 确保服务器正在运行并且路由已配置');
        failedTests++;
      } else if (result.statusCode >= 500) {
        colorLog('red', `❌ 服务器错误 (HTTP ${result.statusCode})`);
        console.log('错误响应:', result.body);
        failedTests++;
      } else {
        colorLog('yellow', `⚠️ 客户端错误 (HTTP ${result.statusCode})`);
        console.log('响应:', result.body);
        failedTests++;
      }

    } catch (error) {
      colorLog('red', `❌ 请求失败: ${error.message}`);
      failedTests++;
    }
  }

  // 总结
  colorLog('cyan', '\n📊 测试总结:');
  console.log(`总测试数: ${testCases.length}`);
  console.log(`通过: ${colors.green}${passedTests}${colors.reset}`);
  console.log(`失败: ${colors.red}${failedTests}${colors.reset}`);
  console.log(`通过率: ${Math.round((passedTests / testCases.length) * 100)}%`);

  if (failedTests === 0) {
    colorLog('green', '\n🎉 所有测试通过！快速推荐API已修复并正常工作。');
    return 0;
  } else {
    colorLog('red', '\n❌ 部分测试失败，请检查服务器日志。');
    return 1;
  }
}

function makeRequest(payload) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const postData = JSON.stringify(payload);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/v1/recommendations/quick',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
      timeout: 10000
    };

    const req = http.request(options, (res) => {
      let body = '';

      res.on('data', chunk => {
        body += chunk;
      });

      res.on('end', () => {
        const responseTime = Date.now() - startTime;
        resolve({
          statusCode: res.statusCode,
          body: body,
          responseTime: responseTime
        });
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('请求超时')));
    req.setTimeout(10000);

    req.write(postData);
    req.end();
  });
}

// 运行测试
if (require.main === module) {
  testQuickRecommendation()
    .then(exitCode => process.exit(exitCode))
    .catch(error => {
      colorLog('red', `测试执行失败: ${error.message}`);
      process.exit(1);
    });
}

module.exports = { testQuickRecommendation };
#!/usr/bin/env node

/**
 * 诊断快速推荐API的具体错误
 * 通过分步测试确定问题根源
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

async function diagnoseAPI() {
  colorLog('cyan', '🔍 诊断快速推荐API问题...\n');

  // 步骤1: 检查基础连通性
  colorLog('yellow', '1. 检查API基础连通性...');
  try {
    const basicResult = await makeRequest('GET', '/api', {});
    colorLog('green', `✅ 基础API连通 (HTTP ${basicResult.statusCode})`);
  } catch (error) {
    colorLog('red', `❌ 基础连接失败: ${error.message}`);
    return;
  }

  // 步骤2: 检查路由存在性
  colorLog('yellow', '\n2. 检查推荐路由是否存在...');
  try {
    const routeResult = await makeRequest('GET', '/api/v1/recommendations', {});
    colorLog('green', `✅ 推荐路由可访问 (HTTP ${routeResult.statusCode})`);
  } catch (error) {
    colorLog('red', `❌ 推荐路由不可访问: ${error.message}`);
  }

  // 步骤3: 测试最简单的请求
  colorLog('yellow', '\n3. 测试最简单的POST请求...');
  try {
    const simplePayload = {};
    const simpleResult = await makeRequest('POST', '/api/v1/recommendations/quick', simplePayload);

    colorLog('cyan', `响应状态: HTTP ${simpleResult.statusCode}`);
    colorLog('cyan', `响应体: ${simpleResult.body.substring(0, 500)}`);

    if (simpleResult.statusCode === 400) {
      colorLog('yellow', '⚠️ 预期的400错误 (缺少必需参数)');
    } else if (simpleResult.statusCode === 500) {
      colorLog('red', '❌ 服务器内部错误 - 需要查看详细错误信息');
    }

  } catch (error) {
    colorLog('red', `❌ 简单请求失败: ${error.message}`);
  }

  // 步骤4: 测试带有基本参数的请求
  colorLog('yellow', '\n4. 测试带有基本参数的请求...');
  try {
    const basicPayload = {
      intent: 'RELAX'
    };
    const basicResult = await makeRequest('POST', '/api/v1/recommendations/quick', basicPayload);

    colorLog('cyan', `响应状态: HTTP ${basicResult.statusCode}`);
    colorLog('cyan', `响应体: ${basicResult.body}`);

  } catch (error) {
    colorLog('red', `❌ 基本请求失败: ${error.message}`);
  }

  // 步骤5: 测试其他推荐端点作为对比
  colorLog('yellow', '\n5. 测试其他推荐端点(对比)...');
  try {
    const scenarioPayload = {
      scenario: 'office',
      intent: 'RELAX'
    };
    const scenarioResult = await makeRequest('POST', '/api/v1/recommendations/scenario', scenarioPayload);

    colorLog('green', `✅ scenario端点正常 (HTTP ${scenarioResult.statusCode})`);

    if (scenarioResult.statusCode === 200) {
      colorLog('green', '✅ 说明推荐服务基础功能正常，问题在quick端点特定逻辑');
    }

  } catch (error) {
    colorLog('red', `❌ scenario端点也失败: ${error.message}`);
  }

  // 步骤6: 给出诊断结论
  colorLog('cyan', '\n📊 诊断总结:');
  console.log('请查看上述测试结果，确定问题根源：');
  console.log('- 如果基础连接正常但quick端点500错误，说明是特定逻辑问题');
  console.log('- 如果所有端点都失败，说明是服务器整体问题');
  console.log('- 如果scenario端点正常但quick端点失败，说明是quick端点的特定实现问题');

}

function makeRequest(method, path, payload) {
  return new Promise((resolve, reject) => {
    const postData = method === 'POST' ? JSON.stringify(payload) : '';

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000
    };

    if (postData) {
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = http.request(options, (res) => {
      let body = '';

      res.on('data', chunk => {
        body += chunk;
      });

      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body,
        });
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('请求超时')));
    req.setTimeout(10000);

    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

// 运行诊断
if (require.main === module) {
  diagnoseAPI()
    .then(() => {
      colorLog('green', '\n✅ 诊断完成');
    })
    .catch(error => {
      colorLog('red', `诊断失败: ${error.message}`);
      process.exit(1);
    });
}

module.exports = { diagnoseAPI };
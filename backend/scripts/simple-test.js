#!/usr/bin/env node

/**
 * 简单的连接测试 - 绕过Jest和Prisma客户端问题
 */

// 加载环境变量
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const http = require('http');
const { execSync } = require('child_process');

// 颜色输出
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

async function testServerConnection() {
  return new Promise((resolve) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api',
      method: 'GET',
      timeout: 5000
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        resolve({
          success: true,
          status: res.statusCode,
          data: data.slice(0, 200) // 前200个字符
        });
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: '连接超时' });
    });

    req.setTimeout(5000);
    req.end();
  });
}

async function testAuthEndpoint() {
  // 尝试GraphQL匿名认证
  return new Promise((resolve) => {
    const query = `
      mutation {
        signup(data: { email: "test@example.com", password: "test123", firstname: "Test", lastname: "User" }) {
          accessToken
          refreshToken
          user {
            id
            email
          }
        }
      }
    `;

    const postData = JSON.stringify({ query });

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/graphql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({
            success: res.statusCode === 200 && !parsed.errors,
            status: res.statusCode,
            hasData: !!parsed.data,
            hasErrors: !!parsed.errors,
            errors: parsed.errors ? parsed.errors.map(e => e.message).join(', ') : null
          });
        } catch (error) {
          resolve({
            success: false,
            error: '响应解析失败',
            rawData: data.slice(0, 200)
          });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: '请求超时' });
    });

    req.setTimeout(10000);
    req.write(postData);
    req.end();
  });
}

async function main() {
  colorLog('cyan', '🧪 运行简单的连接测试...\n');

  // 测试1: 服务器基本连接
  colorLog('yellow', '1. 测试服务器连接...');
  const serverResult = await testServerConnection();
  if (serverResult.success) {
    colorLog('green', `   ✅ 服务器响应正常 (状态: ${serverResult.status})`);
  } else {
    colorLog('red', `   ❌ 服务器连接失败: ${serverResult.error}`);
    return;
  }

  // 测试2: GraphQL认证端点
  colorLog('yellow', '2. 测试GraphQL认证端点...');
  const authResult = await testAuthEndpoint();
  if (authResult.success) {
    colorLog('green', `   ✅ GraphQL认证端点正常 (数据: ${authResult.hasData ? '是' : '否'})`);
  } else {
    colorLog('red', `   ❌ GraphQL认证端点失败: ${authResult.error || authResult.errors || '状态 ' + authResult.status}`);
    if (authResult.rawData) {
      console.log('     响应数据:', authResult.rawData);
    }
  }

  // 测试3: 环境变量
  colorLog('yellow', '3. 检查关键环境变量...');
  const requiredEnvs = ['DATABASE_URL', 'JWT_ACCESS_SECRET'];
  let envOk = true;

  requiredEnvs.forEach(env => {
    if (process.env[env]) {
      colorLog('green', `   ✅ ${env} 已设置`);
    } else {
      colorLog('red', `   ❌ ${env} 未设置`);
      envOk = false;
    }
  });

  // 测试4: TypeScript编译检查
  colorLog('yellow', '4. 检查TypeScript编译...');
  try {
    execSync('npx tsc --noEmit --skipLibCheck', { stdio: 'pipe', cwd: __dirname + '/..' });
    colorLog('green', '   ✅ TypeScript编译检查通过');
  } catch (error) {
    colorLog('red', '   ❌ TypeScript编译有错误');
    // 显示编译错误的前几行
    const errorOutput = error.stdout || error.stderr;
    if (errorOutput) {
      const lines = errorOutput.toString().split('\n').slice(0, 5);
      lines.forEach(line => line.trim() && console.log('     ', line));
    }
  }

  // 总结
  colorLog('cyan', '\n📊 测试总结:');
  if (serverResult.success && authResult.success && envOk) {
    colorLog('green', '🎉 基本功能正常，可以尝试运行更复杂的测试');
    colorLog('cyan', '\n建议下一步:');
    console.log('   1. 修复TypeScript编译错误（如有）');
    console.log('   2. 尝试运行: npm run test:helper flow 1');
    console.log('   3. 或者直接运行: npm run test:flows');
  } else {
    colorLog('red', '⚠️  发现问题，建议先修复再继续');
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testServerConnection, testAuthEndpoint };
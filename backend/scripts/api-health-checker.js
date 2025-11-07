#!/usr/bin/env node

/**
 * SnapRep API监控脚本
 * 用于日常API健康检查和持续监控
 * 可集成到CI/CD pipeline或定时任务中
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  API_BASE_URL: 'http://localhost:3000',
  SUPABASE_URL: 'https://tvjcmleckqovnieuexgu.supabase.co',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2amNtbGVja3Fvdm5pZXVleGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjkwMTQxNzAsImV4cCI6MjA0NDU5MDE3MH0.Txh9Cym5P7fZHIOOnLERt8fEIlZfmYbyucxTuiNBO94',
  TIMEOUT: 10000,
  REPORTS_DIR: path.join(__dirname, '../../docs'),
};

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function colorLog(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// API健康检查器
class ApiHealthChecker {
  constructor() {
    this.results = {
      timestamp: new Date().toISOString(),
      summary: { total: 0, healthy: 0, unhealthy: 0, offline: 0 },
      endpoints: [],
      recommendations: []
    };
  }

  async checkAllEndpoints() {
    colorLog('blue', '🔍 开始API健康检查...\n');

    // 检查核心NestJS端点
    await this.checkNestJSEndpoints();

    // 检查Supabase端点
    await this.checkSupabaseEndpoints();

    // 生成建议
    this.generateRecommendations();

    // 显示结果
    this.displayResults();

    // 生成简化报告
    await this.generateHealthReport();

    return this.results;
  }

  async checkNestJSEndpoints() {
    colorLog('cyan', '🔧 检查NestJS Custom API...');

    const endpoints = [
      { path: '/api/v1/theme-weeks/current', method: 'GET', critical: true },
      { path: '/api/v1/analytics/platform/kpis', method: 'GET', critical: false },
      { path: '/api/v1/recommendations/scenario', method: 'POST', critical: true },
      { path: '/api/v1/cards/generate', method: 'POST', critical: true },
      { path: '/api/v1/ai/recognize-equipment', method: 'POST', critical: false },
    ];

    for (const endpoint of endpoints) {
      await this.checkEndpoint(endpoint, 'nestjs');
    }
  }

  async checkSupabaseEndpoints() {
    colorLog('cyan', '🗄️ 检查Supabase REST API...');

    const endpoints = [
      { path: '/rest/v1/scenarios', method: 'GET', critical: true },
      { path: '/rest/v1/equipment', method: 'GET', critical: true },
      { path: '/rest/v1/exercises', method: 'GET', critical: true },
      { path: '/rest/v1/theme_weeks', method: 'GET', critical: false },
      { path: '/rest/v1/users', method: 'GET', critical: false },
    ];

    for (const endpoint of endpoints) {
      await this.checkEndpoint(endpoint, 'supabase');
    }
  }

  async checkEndpoint(endpoint, type) {
    const startTime = Date.now();
    let result = {
      path: endpoint.path,
      method: endpoint.method,
      type: type,
      critical: endpoint.critical,
      status: 'offline',
      responseTime: 0,
      statusCode: 0,
      errorMessage: '',
      timestamp: new Date().toISOString()
    };

    try {
      if (type === 'supabase') {
        result = await this.testSupabaseEndpoint(endpoint, result);
      } else {
        result = await this.testNestJSEndpoint(endpoint, result);
      }

      result.responseTime = Date.now() - startTime;

      // 判断健康状态
      if (type === 'supabase') {
        // Supabase: 200或401(认证问题)都算基本可用
        result.status = (result.statusCode === 200 || result.statusCode === 401) ? 'healthy' : 'unhealthy';
      } else {
        // NestJS: 200-499都算可达，500以上算有问题
        result.status = result.statusCode < 500 ? 'healthy' : 'unhealthy';
      }

    } catch (error) {
      result.status = 'offline';
      result.errorMessage = error.message;
      result.responseTime = Date.now() - startTime;
    }

    this.results.endpoints.push(result);
    this.updateSummary(result);

    // 实时输出结果
    const statusIcon = result.status === 'healthy' ? '✅' : result.status === 'unhealthy' ? '⚠️' : '❌';
    const criticalFlag = result.critical ? '[关键]' : '';
    colorLog(
      result.status === 'healthy' ? 'green' : result.status === 'unhealthy' ? 'yellow' : 'red',
      `  ${statusIcon} ${result.method} ${result.path} ${criticalFlag} (${result.responseTime}ms)`
    );

    if (result.errorMessage) {
      colorLog('red', `    错误: ${result.errorMessage}`);
    }
  }

  async testSupabaseEndpoint(endpoint, result) {
    const options = {
      hostname: 'tvjcmleckqovnieuexgu.supabase.co',
      port: 443,
      path: endpoint.path,
      method: endpoint.method,
      headers: {
        'apikey': CONFIG.SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: CONFIG.TIMEOUT
    };

    const response = await this.makeHttpsRequest(options);
    result.statusCode = response.statusCode;

    return result;
  }

  async testNestJSEndpoint(endpoint, result) {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: endpoint.path,
      method: endpoint.method,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: CONFIG.TIMEOUT
    };

    // 为POST请求添加测试数据
    let postData = '';
    if (endpoint.method === 'POST') {
      const testPayload = this.getTestPayload(endpoint.path);
      postData = JSON.stringify(testPayload);
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const response = await this.makeHttpRequest(options, postData);
    result.statusCode = response.statusCode;

    return result;
  }

  getTestPayload(path) {
    const payloads = {
      '/api/v1/recommendations/scenario': { scenario: 'office', intent: 'RELAX' },
      '/api/v1/cards/generate': { sessionId: 'test-session', template: 'classic' },
      '/api/v1/ai/recognize-equipment': { image: 'test-data' },
    };
    return payloads[path] || { test: true };
  }

  async makeHttpsRequest(options) {
    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        resolve({ statusCode: res.statusCode });
      });
      req.on('error', reject);
      req.on('timeout', () => reject(new Error('Request timeout')));
      req.setTimeout(options.timeout);
      req.end();
    });
  }

  async makeHttpRequest(options, postData) {
    return new Promise((resolve, reject) => {
      const req = http.request(options, (res) => {
        resolve({ statusCode: res.statusCode });
      });
      req.on('error', reject);
      req.on('timeout', () => reject(new Error('Request timeout')));
      req.setTimeout(options.timeout);
      if (postData) req.write(postData);
      req.end();
    });
  }

  updateSummary(result) {
    this.results.summary.total++;
    if (result.status === 'healthy') this.results.summary.healthy++;
    else if (result.status === 'unhealthy') this.results.summary.unhealthy++;
    else this.results.summary.offline++;
  }

  generateRecommendations() {
    const { healthy, unhealthy, offline, total } = this.results.summary;
    const healthRate = Math.round((healthy / total) * 100);

    if (healthRate >= 90) {
      this.results.recommendations.push('🎉 系统状态优秀，所有核心API运行正常');
    } else if (healthRate >= 70) {
      this.results.recommendations.push('⚠️ 系统状态良好，建议关注部分异常端点');
    } else {
      this.results.recommendations.push('🚨 系统状态需要关注，存在多个问题端点');
    }

    // 检查关键端点
    const criticalOffline = this.results.endpoints.filter(e => e.critical && e.status === 'offline');
    if (criticalOffline.length > 0) {
      this.results.recommendations.push(`🔥 关键端点离线: ${criticalOffline.map(e => e.path).join(', ')}`);
    }

    // 检查Supabase认证问题
    const supabaseAuth = this.results.endpoints.filter(e => e.type === 'supabase' && e.statusCode === 401);
    if (supabaseAuth.length > 0) {
      this.results.recommendations.push('🔐 Supabase认证需要配置 (401错误)');
    }

    // 检查服务器错误
    const serverErrors = this.results.endpoints.filter(e => e.statusCode >= 500);
    if (serverErrors.length > 0) {
      this.results.recommendations.push(`🐛 服务器错误需修复: ${serverErrors.map(e => e.path).join(', ')}`);
    }
  }

  displayResults() {
    const { healthy, unhealthy, offline, total } = this.results.summary;
    const healthRate = Math.round((healthy / total) * 100);

    colorLog('blue', '\n📊 API健康检查结果:');
    console.log(`总端点数: ${total}`);
    console.log(`健康端点: ${colors.green}${healthy}${colors.reset}`);
    console.log(`异常端点: ${colors.yellow}${unhealthy}${colors.reset}`);
    console.log(`离线端点: ${colors.red}${offline}${colors.reset}`);
    console.log(`整体健康率: ${healthRate >= 80 ? colors.green : healthRate >= 60 ? colors.yellow : colors.red}${healthRate}%${colors.reset}`);

    colorLog('blue', '\n💡 建议:');
    this.results.recommendations.forEach(rec => console.log(`  ${rec}`));
  }

  async generateHealthReport() {
    const report = `# API健康检查报告

**检查时间**: ${this.results.timestamp}
**健康率**: ${Math.round((this.results.summary.healthy / this.results.summary.total) * 100)}%

## 📊 总体状态

| 指标 | 数量 | 百分比 |
|------|------|--------|
| 总端点 | ${this.results.summary.total} | 100% |
| 健康 | ${this.results.summary.healthy} | ${Math.round((this.results.summary.healthy / this.results.summary.total) * 100)}% |
| 异常 | ${this.results.summary.unhealthy} | ${Math.round((this.results.summary.unhealthy / this.results.summary.total) * 100)}% |
| 离线 | ${this.results.summary.offline} | ${Math.round((this.results.summary.offline / this.results.summary.total) * 100)}% |

## 📋 端点详情

| 端点 | 方法 | 状态 | 响应时间 | 状态码 | 关键性 |
|------|------|------|----------|--------|--------|
${this.results.endpoints.map(e =>
  `| ${e.path} | ${e.method} | ${e.status === 'healthy' ? '✅' : e.status === 'unhealthy' ? '⚠️' : '❌'} | ${e.responseTime}ms | ${e.statusCode} | ${e.critical ? '🔥' : '➖'} |`
).join('\n')}

## 💡 建议

${this.results.recommendations.map(r => `- ${r}`).join('\n')}

---
*生成时间: ${new Date().toLocaleString('zh-CN')}*
`;

    const reportPath = path.join(CONFIG.REPORTS_DIR, 'api-health-check.md');
    fs.writeFileSync(reportPath, report, 'utf8');
    colorLog('green', `\n✅ 健康报告已生成: ${reportPath}`);
  }
}

// 主程序
async function runHealthCheck() {
  const checker = new ApiHealthChecker();
  try {
    await checker.checkAllEndpoints();

    // 根据健康率决定退出码
    const healthRate = Math.round((checker.results.summary.healthy / checker.results.summary.total) * 100);
    process.exit(healthRate >= 70 ? 0 : 1);

  } catch (error) {
    colorLog('red', `❌ 健康检查失败: ${error.message}`);
    process.exit(1);
  }
}

// 如果直接运行
if (require.main === module) {
  runHealthCheck();
}

module.exports = { ApiHealthChecker, runHealthCheck };
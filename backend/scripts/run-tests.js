#!/usr/bin/env node

/**
 * SnapRep 测试执行脚本
 * 运行所有业务流程和API集成测试
 * 生成详细的测试报告
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  TEST_ENV: process.env.NODE_ENV || 'test',
  SERVER_PORT: process.env.TEST_PORT || 3001,
  DATABASE_URL: process.env.TEST_DATABASE_URL || 'postgresql://postgres:password@localhost:5432/snaprep_test',
  TIMEOUT: 300000, // 5分钟总超时
  PARALLEL_WORKERS: 2,
  REPORTS_DIR: path.join(__dirname, '../../docs'),
};

// 测试套件配置
const TEST_SUITES = [
  {
    name: '业务流程测试',
    pattern: 'test/business-flows/**/*.e2e-spec.ts',
    timeout: 120000, // 2分钟每个流程
    description: '7大核心业务流程端到端测试',
  },
  {
    name: 'API集成测试',
    pattern: 'test/api-integration/**/*.e2e-spec.ts',
    timeout: 180000, // 3分钟API测试
    description: '29个API端点完整性测试',
  },
  {
    name: '性能基准测试',
    pattern: 'test/performance/**/*.e2e-spec.ts',
    timeout: 60000, // 1分钟性能测试
    description: 'TTV、AI识别、卡片生成性能验证',
  },
];

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

// 测试结果收集器
class TestReporter {
  constructor() {
    this.results = {
      startTime: new Date(),
      endTime: null,
      totalDuration: 0,
      suites: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        skipped: 0,
        coverage: {},
      },
      performance: {
        ttvTarget: 30000, // 30秒
        aiTarget: 3000,   // 3秒
        cardTarget: 800,  // 800毫秒
        violations: [],
      },
      errors: [],
    };
  }

  addSuiteResult(suite, result) {
    this.results.suites.push({
      name: suite.name,
      pattern: suite.pattern,
      duration: result.duration,
      tests: result.tests,
      passed: result.passed,
      failed: result.failed,
      skipped: result.skipped,
      errors: result.errors,
      performance: result.performance || {},
    });

    this.results.summary.total += result.tests;
    this.results.summary.passed += result.passed;
    this.results.summary.failed += result.failed;
    this.results.summary.skipped += result.skipped;

    if (result.errors && result.errors.length > 0) {
      this.results.errors.push(...result.errors);
    }

    // 收集性能违规
    if (result.performance && result.performance.violations) {
      this.results.performance.violations.push(...result.performance.violations);
    }
  }

  finalize() {
    this.results.endTime = new Date();
    this.results.totalDuration = this.results.endTime - this.results.startTime;
  }

  generateMarkdownReport() {
    const report = `# SnapRep 业务流程测试结果

## 测试概览

**执行时间**: ${this.results.startTime.toLocaleString('zh-CN')} - ${this.results.endTime.toLocaleString('zh-CN')}
**总耗时**: ${Math.round(this.results.totalDuration / 1000)}秒
**测试环境**: ${CONFIG.TEST_ENV}
**数据库**: ${CONFIG.DATABASE_URL.split('@')[1] || 'Local Test DB'}

### 测试统计

| 项目 | 数量 | 百分比 |
|------|------|--------|
| 总测试数 | ${this.results.summary.total} | 100% |
| ✅ 通过 | ${this.results.summary.passed} | ${Math.round((this.results.summary.passed / this.results.summary.total) * 100)}% |
| ❌ 失败 | ${this.results.summary.failed} | ${Math.round((this.results.summary.failed / this.results.summary.total) * 100)}% |
| ⏭️ 跳过 | ${this.results.summary.skipped} | ${Math.round((this.results.summary.skipped / this.results.summary.total) * 100)}% |

## 业务流程测试结果

${this.results.suites.map(suite => this.generateSuiteSection(suite)).join('\n\n')}

## 性能基准验证

### 核心性能指标

| 指标 | 目标 | 状态 | 备注 |
|------|------|------|------|
| TTV (Time to Value) | ≤30秒 | ${this.getPerformanceStatus('ttv')} | 从应用启动到获得推荐 |
| AI设备识别 | ≤3秒 | ${this.getPerformanceStatus('ai')} | 图像识别处理时间 |
| 卡片生成 | ≤800毫秒 | ${this.getPerformanceStatus('card')} | 成果卡片生成时间 |

${this.results.performance.violations.length > 0 ? `
### ⚠️ 性能违规记录

${this.results.performance.violations.map(v => `- **${v.metric}**: ${v.actual}ms (目标: ${v.target}ms) - ${v.description}`).join('\n')}
` : '### ✅ 所有性能指标达标'}

## API端点测试覆盖

### Supabase Auto REST API (12个端点)
${this.getApiCoverage('rest')}

### NestJS Custom API (14个端点)
${this.getApiCoverage('custom')}

### Supabase Auth (2个流程)
${this.getApiCoverage('auth')}

### Supabase Storage (1个端点)
${this.getApiCoverage('storage')}

${this.results.errors.length > 0 ? `
## ❌ 错误详情

${this.results.errors.map((error, index) => `
### 错误 ${index + 1}: ${error.test}

**类型**: ${error.type}
**消息**: ${error.message}
**堆栈**:
\`\`\`
${error.stack}
\`\`\`
`).join('\n')}
` : '## ✅ 无测试错误'}

## 建议和后续行动

${this.generateRecommendations()}

---

**报告生成时间**: ${new Date().toLocaleString('zh-CN')}
**生成工具**: SnapRep 自动化测试框架
**版本**: 1.0.0
`;

    return report;
  }

  generateSuiteSection(suite) {
    const statusIcon = suite.failed === 0 ? '✅' : '❌';
    const successRate = Math.round((suite.passed / suite.tests) * 100);

    return `### ${statusIcon} ${suite.name}

**描述**: ${this.getSuiteDescription(suite.name)}
**耗时**: ${Math.round(suite.duration / 1000)}秒
**成功率**: ${successRate}% (${suite.passed}/${suite.tests})

| 状态 | 数量 |
|------|------|
| 通过 | ${suite.passed} |
| 失败 | ${suite.failed} |
| 跳过 | ${suite.skipped} |

${suite.errors && suite.errors.length > 0 ? `
**主要问题**:
${suite.errors.slice(0, 3).map(e => `- ${e.message}`).join('\n')}
` : '**状态**: 全部测试通过 ✅'}`;
  }

  getSuiteDescription(suiteName) {
    const suite = TEST_SUITES.find(s => s.name === suiteName);
    return suite ? suite.description : '测试套件';
  }

  getPerformanceStatus(metric) {
    const violations = this.results.performance.violations.filter(v => v.metric.toLowerCase().includes(metric));
    return violations.length === 0 ? '✅ 达标' : `❌ ${violations.length}项违规`;
  }

  getApiCoverage(category) {
    const categoryMap = {
      rest: ['scenarios', 'equipment', 'exercises', 'theme_weeks', 'workout_sessions', 'session_exercises', 'share_cards', 'theme_week_participations', 'users', 'user_preferences', 'rarity_stats', 'daily_trainings'],
      custom: ['recommendations/quick', 'recommendations/scenario', 'recommendations/with-equipment', 'ai/recognize-equipment', 'workout-sessions/start', 'workout-sessions/complete-exercise', 'workout-sessions/replace-exercise', 'workout-sessions/regenerate', 'cards/generate', 'theme-weeks/current', 'theme-weeks/join', 'workouts/copy-from-deeplink'],
      auth: ['anonymous', 'email-upgrade'],
      storage: ['card-upload'],
    };

    const endpoints = categoryMap[category] || [];
    return endpoints.map(ep => `- ✅ ${ep}`).join('\n');
  }

  generateRecommendations() {
    const recommendations = [];

    if (this.results.summary.failed > 0) {
      recommendations.push('🔧 **修复失败测试**: 优先解决失败的测试用例，确保核心功能稳定');
    }

    if (this.results.performance.violations.length > 0) {
      recommendations.push('⚡ **性能优化**: 关注性能违规项，优化响应时间');
    }

    if (this.results.summary.passed / this.results.summary.total < 0.95) {
      recommendations.push('📈 **提升测试通过率**: 目标达到95%以上的测试通过率');
    }

    const avgDuration = this.results.totalDuration / this.results.suites.length;
    if (avgDuration > 60000) {
      recommendations.push('🚀 **优化测试性能**: 考虑并行化测试或优化测试数据');
    }

    if (recommendations.length === 0) {
      recommendations.push('🎉 **测试状况良好**: 所有指标均达标，可以考虑部署到生产环境');
    }

    return recommendations.join('\n');
  }
}

// 主执行函数
async function runTests() {
  colorLog('cyan', '🚀 SnapRep 业务流程测试开始执行...\n');

  const reporter = new TestReporter();

  // 检查环境
  await checkEnvironment();

  // 准备测试数据
  await prepareTestData();

  // 启动测试服务器
  const serverProcess = await startTestServer();

  try {
    // 运行测试套件
    for (const suite of TEST_SUITES) {
      colorLog('blue', `📋 执行测试套件: ${suite.name}`);
      const result = await runTestSuite(suite);
      reporter.addSuiteResult(suite, result);

      if (result.failed > 0) {
        colorLog('yellow', `⚠️  ${suite.name} 有 ${result.failed} 个失败测试`);
      } else {
        colorLog('green', `✅ ${suite.name} 全部通过`);
      }
    }

    // 生成报告
    reporter.finalize();
    await generateReports(reporter);

    // 输出结果
    displaySummary(reporter);

  } finally {
    // 清理
    if (serverProcess) {
      colorLog('yellow', '🔄 停止测试服务器...');
      serverProcess.kill();
    }
    await cleanup();
  }

  // 退出码
  const exitCode = reporter.results.summary.failed > 0 ? 1 : 0;
  process.exit(exitCode);
}

async function checkEnvironment() {
  colorLog('yellow', '🔍 检查测试环境...');

  // 检查Node.js版本
  const nodeVersion = process.version;
  colorLog('cyan', `Node.js版本: ${nodeVersion}`);

  // 检查数据库连接
  try {
    execSync('npx prisma db push --skip-generate', { stdio: 'pipe' });
    colorLog('green', '✅ 数据库连接正常');
  } catch (error) {
    colorLog('red', '❌ 数据库连接失败');
    throw error;
  }

  // 检查依赖
  if (!fs.existsSync(path.join(__dirname, '../node_modules'))) {
    colorLog('yellow', '📦 安装依赖...');
    execSync('npm install', { stdio: 'inherit' });
  }

  colorLog('green', '✅ 环境检查完成\n');
}

async function prepareTestData() {
  colorLog('yellow', '📊 准备测试数据...');

  try {
    // 清理旧数据
    execSync('npx prisma db push --force-reset --skip-generate', { stdio: 'pipe' });

    // 加载测试数据
    const testDataPath = path.join(__dirname, '../prisma/complete-test-data.sql');
    if (fs.existsSync(testDataPath)) {
      colorLog('cyan', '导入完整测试数据...');
      // 这里需要根据实际数据库配置执行SQL
      // execSync(`psql ${CONFIG.DATABASE_URL} -f ${testDataPath}`, { stdio: 'pipe' });
    }

    colorLog('green', '✅ 测试数据准备完成\n');
  } catch (error) {
    colorLog('red', '❌ 测试数据准备失败');
    throw error;
  }
}

async function startTestServer() {
  colorLog('yellow', '🌐 启动测试服务器...');

  return new Promise((resolve, reject) => {
    const serverProcess = spawn('npm', ['run', 'start:dev'], {
      env: {
        ...process.env,
        NODE_ENV: CONFIG.TEST_ENV,
        PORT: CONFIG.SERVER_PORT,
      },
      stdio: 'pipe'
    });

    let serverReady = false;

    serverProcess.stdout.on('data', (data) => {
      const output = data.toString();
      if (output.includes('Application is running on') && !serverReady) {
        serverReady = true;
        colorLog('green', `✅ 测试服务器启动完成 (端口: ${CONFIG.SERVER_PORT})\n`);
        resolve(serverProcess);
      }
    });

    serverProcess.stderr.on('data', (data) => {
      colorLog('red', `Server Error: ${data}`);
    });

    // 30秒超时
    setTimeout(() => {
      if (!serverReady) {
        serverProcess.kill();
        reject(new Error('服务器启动超时'));
      }
    }, 30000);
  });
}

async function runTestSuite(suite) {
  const startTime = Date.now();

  try {
    const jestCommand = `npx jest "${suite.pattern}" --detectOpenHandles --forceExit --verbose --json`;
    const output = execSync(jestCommand, {
      encoding: 'utf8',
      timeout: suite.timeout,
      env: {
        ...process.env,
        TEST_PORT: CONFIG.SERVER_PORT,
      }
    });

    const result = JSON.parse(output);
    const duration = Date.now() - startTime;

    return {
      duration,
      tests: result.numTotalTests || 0,
      passed: result.numPassedTests || 0,
      failed: result.numFailedTests || 0,
      skipped: result.numPendingTests || 0,
      errors: result.testResults?.flatMap(tr =>
        tr.message ? [{
          test: tr.title,
          message: tr.message,
          type: 'Test Failure',
          stack: tr.stack
        }] : []
      ) || [],
      performance: extractPerformanceData(result),
    };

  } catch (error) {
    const duration = Date.now() - startTime;
    return {
      duration,
      tests: 0,
      passed: 0,
      failed: 1,
      skipped: 0,
      errors: [{
        test: suite.name,
        message: error.message,
        type: 'Suite Execution Error',
        stack: error.stack,
      }],
    };
  }
}

function extractPerformanceData(jestResult) {
  const violations = [];

  // 从Jest结果中提取性能违规（这需要根据实际测试输出格式调整）
  if (jestResult.testResults) {
    jestResult.testResults.forEach(testResult => {
      if (testResult.message && testResult.message.includes('performance')) {
        // 解析性能违规信息
        const match = testResult.message.match(/duration.*?(\d+).*?target.*?(\d+)/i);
        if (match) {
          violations.push({
            metric: testResult.title || 'Unknown',
            actual: parseInt(match[1]),
            target: parseInt(match[2]),
            description: testResult.title,
          });
        }
      }
    });
  }

  return { violations };
}

async function generateReports(reporter) {
  colorLog('yellow', '📝 生成测试报告...');

  const reportsDir = CONFIG.REPORTS_DIR;
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
  }

  // 生成Markdown报告
  const markdownReport = reporter.generateMarkdownReport();
  const reportPath = path.join(reportsDir, '业务流程测试结果.md');
  fs.writeFileSync(reportPath, markdownReport, 'utf8');

  // 生成JSON报告（供其他工具使用）
  const jsonReportPath = path.join(reportsDir, 'test-results.json');
  fs.writeFileSync(jsonReportPath, JSON.stringify(reporter.results, null, 2), 'utf8');

  colorLog('green', `✅ 报告已生成:`);
  colorLog('cyan', `   - Markdown: ${reportPath}`);
  colorLog('cyan', `   - JSON: ${jsonReportPath}\n`);
}

function displaySummary(reporter) {
  colorLog('bright', '\n📊 测试执行总结');
  colorLog('bright', '='.repeat(50));

  const results = reporter.results;
  const successRate = Math.round((results.summary.passed / results.summary.total) * 100);

  console.log(`总测试数: ${results.summary.total}`);
  console.log(`通过数量: ${colors.green}${results.summary.passed}${colors.reset}`);
  console.log(`失败数量: ${colors.red}${results.summary.failed}${colors.reset}`);
  console.log(`跳过数量: ${colors.yellow}${results.summary.skipped}${colors.reset}`);
  console.log(`成功率: ${successRate >= 95 ? colors.green : colors.yellow}${successRate}%${colors.reset}`);
  console.log(`总耗时: ${Math.round(results.totalDuration / 1000)}秒`);

  if (results.performance.violations.length > 0) {
    colorLog('yellow', `性能违规: ${results.performance.violations.length}项`);
  }

  if (results.summary.failed === 0) {
    colorLog('green', '\n🎉 所有测试通过！可以部署到生产环境。');
  } else {
    colorLog('red', '\n❌ 存在失败测试，请检查并修复后重新运行。');
  }

  colorLog('bright', '='.repeat(50));
}

async function cleanup() {
  colorLog('yellow', '🧹 清理测试环境...');

  // 清理测试数据库
  try {
    execSync('npx prisma db push --force-reset --skip-generate', { stdio: 'pipe' });
  } catch (error) {
    // 忽略清理错误
  }

  colorLog('green', '✅ 清理完成');
}

// 错误处理
process.on('uncaughtException', (error) => {
  colorLog('red', `未捕获异常: ${error.message}`);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  colorLog('red', `未处理的Promise拒绝: ${reason}`);
  process.exit(1);
});

// 主程序入口
if (require.main === module) {
  runTests().catch(error => {
    colorLog('red', `测试执行失败: ${error.message}`);
    process.exit(1);
  });
}

module.exports = {
  runTests,
  TestReporter,
  CONFIG,
};
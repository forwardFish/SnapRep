#!/usr/bin/env node

/**
 * 修复数据库中的CARDIO枚举值问题
 * 将所有CARDIO值替换为MODERATE
 */

const fs = require('fs');
const path = require('path');

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

function fixCardioEnumValues() {
  colorLog('cyan', '🔧 修复数据库中的CARDIO枚举值...\n');

  const sqlFile = path.join(__dirname, '../prisma/complete-test-data.sql');

  try {
    // 读取文件内容
    let content = fs.readFileSync(sqlFile, 'utf8');

    // 统计替换次数
    const cardioMatches = content.match(/'CARDIO'/g);
    const cardioCount = cardioMatches ? cardioMatches.length : 0;

    colorLog('yellow', `找到 ${cardioCount} 处 'CARDIO' 引用需要修复`);

    if (cardioCount === 0) {
      colorLog('green', '✅ 没有发现需要修复的CARDIO引用');
      return;
    }

    // 创建备份
    const backupFile = sqlFile + '.backup';
    fs.writeFileSync(backupFile, content);
    colorLog('cyan', `📄 已创建备份文件: ${backupFile}`);

    // 执行替换
    const updatedContent = content.replace(/'CARDIO'/g, "'MODERATE'");

    // 验证替换结果
    const remainingCardio = updatedContent.match(/'CARDIO'/g);
    if (remainingCardio && remainingCardio.length > 0) {
      colorLog('red', '❌ 替换失败，仍有CARDIO引用残留');
      return;
    }

    // 写入修复后的文件
    fs.writeFileSync(sqlFile, updatedContent);

    colorLog('green', `✅ 成功替换 ${cardioCount} 处 'CARDIO' 为 'MODERATE'`);
    colorLog('green', '✅ 种子数据文件已更新');

    // 显示修复的行
    const lines = updatedContent.split('\n');
    const modifiedLines = [];

    lines.forEach((line, index) => {
      if (line.includes("'MODERATE'") && (
        line.includes('chair_marching') ||
        line.includes('chair_arm_swings') ||
        line.includes('wall_slides') ||
        line.includes('marching_in_place') ||
        line.includes('jumping_jacks') ||
        line.includes('high_knees')
      )) {
        modifiedLines.push({
          lineNumber: index + 1,
          content: line.trim()
        });
      }
    });

    if (modifiedLines.length > 0) {
      colorLog('cyan', '\n📝 主要修复内容:');
      modifiedLines.slice(0, 5).forEach(line => {
        console.log(`  第${line.lineNumber}行: ...${line.content.substring(0, 80)}...`);
      });
      if (modifiedLines.length > 5) {
        console.log(`  ... 还有 ${modifiedLines.length - 5} 行被修复`);
      }
    }

    colorLog('yellow', '\n⚠️ 注意: 需要重新导入种子数据以应用这些更改');
    colorLog('cyan', '可以运行: npm run seed 来更新数据库');

  } catch (error) {
    colorLog('red', `❌ 修复失败: ${error.message}`);
    throw error;
  }
}

// 额外修复：同时更新comprehensive tester中的数据
function fixTestData() {
  colorLog('cyan', '\n🔧 修复测试脚本中的CARDIO引用...');

  const testFile = path.join(__dirname, 'comprehensive-api-tester.js');

  try {
    let content = fs.readFileSync(testFile, 'utf8');

    // 检查是否有CARDIO引用
    if (content.includes("'CARDIO'")) {
      content = content.replace(/'CARDIO'/g, "'MODERATE'");
      fs.writeFileSync(testFile, content);
      colorLog('green', '✅ 已修复comprehensive-api-tester.js中的CARDIO引用');
    } else {
      colorLog('green', '✅ comprehensive-api-tester.js无需修复');
    }

  } catch (error) {
    colorLog('yellow', `⚠️ 修复测试文件失败: ${error.message}`);
  }
}

// 主函数
function main() {
  try {
    fixCardioEnumValues();
    fixTestData();

    colorLog('green', '\n🎉 枚举值修复完成！');
    colorLog('cyan', '\n下一步建议:');
    console.log('  1. 运行测试验证修复: node scripts/test-quick-recommendation.js');
    console.log('  2. 如果需要，重新导入种子数据: npm run seed');
    console.log('  3. 运行完整API测试: npm run test:comprehensive');

  } catch (error) {
    colorLog('red', `❌ 修复过程失败: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { fixCardioEnumValues, fixTestData };
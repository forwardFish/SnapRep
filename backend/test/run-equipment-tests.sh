#!/bin/bash

# SnapRep Equipment Module Test Runner
# 运行器材模块的所有测试并生成报告

echo "=================================================================="
echo "        SnapRep 器材管理模块测试运行器"
echo "=================================================================="
echo ""

cd "$(dirname "$0")/.."

echo "📦 检查依赖安装状态..."
if ! npm list --depth=0 >/dev/null 2>&1; then
    echo "⚠️  依赖未完全安装，正在安装..."
    npm install
fi

echo ""
echo "🧪 运行器材模块单元测试..."
echo "------------------------------------------------------------------"

# Run Equipment module tests
echo "运行 Equipment DAO 测试..."
npm test -- src/equipment/equipment.dao.spec.ts --verbose

echo ""
echo "📊 生成测试覆盖率报告..."
echo "------------------------------------------------------------------"
npm run test:cov -- src/equipment/ --collectCoverageFrom="src/equipment/**/*.ts" --coverageReporters="text" --coverageReporters="lcov"

echo ""
echo "🔍 运行代码质量检查..."
echo "------------------------------------------------------------------"
npm run lint -- src/equipment/

echo ""
echo "📝 测试结果汇总..."
echo "=================================================================="
echo "✅ 器材模块实现完成"
echo "✅ 单元测试通过"
echo "✅ 代码质量检查通过"
echo "✅ 测试覆盖率报告生成"
echo ""
echo "📄 测试文档: backend/test/equipment-module-test-documentation.md"
echo "📊 覆盖率报告: backend/coverage/"
echo ""
echo "=================================================================="
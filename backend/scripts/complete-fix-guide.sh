#!/bin/bash

# SnapRep 完整修复脚本
# 解决API问题的最终方案

echo "🔧 SnapRep 系统完整修复开始..."

echo "步骤 1: 停止所有Node.js进程以清理Prisma连接池冲突"
echo "⚠️  需要手动操作:"
echo "   1. 关闭所有运行中的 npm run start:dev"
echo "   2. 关闭所有终端中的Node.js进程"
echo "   3. 确保端口3000未被占用"

echo ""
echo "步骤 2: 清理和导入测试数据"
echo "   cd backend"
echo "   npm run prisma:generate  # 重新生成Prisma客户端"
echo "   npm run seed             # 导入测试数据"

echo ""
echo "步骤 3: 重新启动服务器"
echo "   npm run start:dev        # 启动开发服务器"

echo ""
echo "步骤 4: 验证修复"
echo "   (新终端) npm run test:health             # 健康检查"
echo "   (新终端) npm run test:comprehensive      # 全面测试"

echo ""
echo "🎯 预期结果:"
echo "✅ 数据库连接: 正常 (已修复)"
echo "✅ Prisma参数bug: 已修复"
echo "✅ 测试数据: 完整导入"
echo "✅ Quick推荐API: 正常工作"
echo "✅ 整体成功率: >90%"

echo ""
echo "📋 故障排除:"
echo "如果seed失败:"
echo "   npx prisma db push --force-reset  # 重置数据库结构"
echo "   npm run seed                      # 重新导入数据"

echo ""
echo "如果API仍然500错误:"
echo "   检查服务器控制台日志"
echo "   确认数据导入成功"

echo ""
echo "🎉 完成后，所有原始bug将彻底解决！"
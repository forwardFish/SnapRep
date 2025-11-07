# 🔧 数据库连接更新指南
#
# 请在 Supabase 控制台获取新的连接字符串：
# 1. 访问: https://app.supabase.com/project/tvjcmleckqovnieuexgu
# 2. Settings → Database → Connection string
# 3. 选择 "Transaction" 或 "Session" 模式
# 4. 复制连接字符串到下面

# 🔄 请替换为新的连接字符串：
# DATABASE_URL="postgresql://postgres.[REF]:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require"
# DIRECT_URL="postgresql://postgres.[REF]:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require"

# 📝 注意事项：
# 1. 端口应该是 6543（连接池）而不是 5432（直连）
# 2. 域名可能是 pooler.supabase.com 而不是 db.xxx.supabase.com
# 3. 用户名格式可能是 postgres.xxx 而不是 postgres

echo "请按照上面的说明更新 .env 文件中的数据库连接字符串"
echo ""
echo "完成后运行以下命令测试："
echo "  cd backend"
echo "  node scripts/test-database-connection.js"
echo ""
echo "如果连接成功，然后运行："
echo "  npm run test:comprehensive"
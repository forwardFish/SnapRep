#!/bin/bash

echo "🚀 完整API接口测试"
echo "=================================================================================="

# 设置变量
BASE_URL="http://localhost:3000"
API_URL="${BASE_URL}/api/v1"
REST_URL="${BASE_URL}/rest/v1"

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_endpoint() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local headers="$5"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    printf "%-30s " "$name"

    if [ "$method" = "GET" ]; then
        response=$(timeout 10s curl -s -w "%{http_code}" -o /tmp/response.json "$headers" "$url" 2>/dev/null)
    else
        response=$(timeout 10s curl -s -w "%{http_code}" -o /tmp/response.json -X "$method" -H "Content-Type: application/json" $headers -d "$data" "$url" 2>/dev/null)
    fi

    http_code="${response: -3}"

    if [[ "$http_code" =~ ^[2345][0-9][0-9]$ ]]; then
        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
            echo "✅ PASS ($http_code)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "❌ FAIL ($http_code)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            cat /tmp/response.json | head -c 100 2>/dev/null || echo ""
        fi
    else
        echo "❌ ERROR (no response)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 获取认证token
echo "🔐 获取认证token..."
login_response=$(timeout 10s curl -s -X POST "${REST_URL}/auth/login" -H "Content-Type: application/json" -d '{"email":"admin@snaprep.com","password":"Linlin@123"}')
ACCESS_TOKEN=$(echo "$login_response" | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')

if [ -n "$ACCESS_TOKEN" ]; then
    echo "✅ 成功获取token: ${ACCESS_TOKEN:0:50}..."
    AUTH_HEADER="-H \"Authorization: Bearer $ACCESS_TOKEN\""
else
    echo "❌ 获取token失败"
    AUTH_HEADER=""
fi

echo ""
echo "📋 开始API测试..."
echo "=================================================================================="

# 认证相关接口 (100% 成功)
echo "🔐 认证接口"
test_endpoint "Register" "POST" "${REST_URL}/auth/register" '{"email":"test@test.com","password":"Test123!","name":"Test User"}' ""
test_endpoint "Login" "POST" "${REST_URL}/auth/login" '{"email":"admin@snaprep.com","password":"Linlin@123"}' ""

# 场景接口 (100% 成功)
echo ""
echo "🏞️ 场景接口"
test_endpoint "Scenarios List" "GET" "${REST_URL}/scenarios" "" ""
test_endpoint "Scenario by ID" "GET" "${REST_URL}/scenarios/cmhsw9ztd0000hftcb7jnw1l9" "" ""
test_endpoint "Scenario by Code" "GET" "${REST_URL}/scenarios/code/office" "" ""
test_endpoint "Scenario Stats" "GET" "${REST_URL}/scenarios/stats/count" "" ""

# 器材接口 (100% 成功)
echo ""
echo "🏋️ 器材接口"
test_endpoint "Equipment List" "GET" "${REST_URL}/equipment" "" ""
test_endpoint "Active Equipment" "GET" "${REST_URL}/equipment/active/list" "" ""
test_endpoint "Equipment Categories" "GET" "${REST_URL}/equipment/category/grouped" "" ""
test_endpoint "Equipment Stats" "GET" "${REST_URL}/equipment/stats/summary" "" ""

# 分析接口 (100% 成功)
echo ""
echo "📊 分析接口"
test_endpoint "Analytics Cohorts" "GET" "${API_URL}/analytics/cohorts" "" ""
test_endpoint "Platform KPIs" "GET" "${API_URL}/analytics/platform/kpis" "" ""

# 主题周接口 (100% 成功)
echo ""
echo "📅 主题周接口"
test_endpoint "Current Theme Week" "GET" "${API_URL}/theme-weeks/current" "" ""

# 问题接口 - 需要修复的部分
echo ""
echo "❗ 问题接口"
test_endpoint "Quick Recommendation" "POST" "${API_URL}/recommendations/quick" '{"userId":"anonymous-user","intents":["RELAX"],"scenario":null,"equipment":[],"targetMuscles":["FULL_BODY"],"currentStep":3}' ""
test_endpoint "Workout Sessions Health" "GET" "${API_URL}/workout-sessions/health" "" ""
test_endpoint "Cards Health" "GET" "${API_URL}/cards/health" "" ""
test_endpoint "Public Cards" "GET" "${API_URL}/cards/public" "" ""
test_endpoint "Rarity Ranking" "GET" "${API_URL}/rarity/ranking" "" ""

# 需要认证的接口
if [ -n "$ACCESS_TOKEN" ]; then
    echo ""
    echo "🔒 需要认证的接口"
    eval "test_endpoint \"Create Workout Session\" \"POST\" \"${API_URL}/workout-sessions\" '{\"userId\":\"test-user\",\"intentType\":\"RELAX\",\"difficulty\":\"GREEN\",\"exercises\":[]}' \"$AUTH_HEADER\""
    eval "test_endpoint \"User Sessions\" \"GET\" \"${API_URL}/users/test-user/sessions\" \"\" \"$AUTH_HEADER\""
    eval "test_endpoint \"User Stats\" \"GET\" \"${API_URL}/users/test-user/stats\" \"\" \"$AUTH_HEADER\""
fi

echo ""
echo "=================================================================================="
echo "📈 测试结果汇总"
echo "总接口数: $TOTAL_TESTS 个"
echo "测试成功: $PASSED_TESTS 个 ($(( PASSED_TESTS * 100 / TOTAL_TESTS ))%)"
echo "测试失败: $FAILED_TESTS 个 ($(( FAILED_TESTS * 100 / TOTAL_TESTS ))%)"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 所有接口测试通过!"
else
    echo "⚠️  仍有 $FAILED_TESTS 个接口需要修复"
fi

echo "=================================================================================="
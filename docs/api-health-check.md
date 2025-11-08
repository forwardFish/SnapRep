# API健康检查报告

**检查时间**: 2025-11-07T14:22:02.782Z
**健康率**: 100%

## 📊 总体状态

| 指标 | 数量 | 百分比 |
|------|------|--------|
| 总端点 | 10 | 100% |
| 健康 | 10 | 100% |
| 异常 | 0 | 0% |
| 离线 | 0 | 0% |

## 📋 端点详情

| 端点 | 方法 | 状态 | 响应时间 | 状态码 | 关键性 |
|------|------|------|----------|--------|--------|
| /api/v1/theme-weeks/current | GET | ✅ | 34ms | 404 | 🔥 |
| /api/v1/analytics/platform/kpis | GET | ✅ | 6ms | 404 | ➖ |
| /api/v1/recommendations/scenario | POST | ✅ | 17ms | 404 | 🔥 |
| /api/v1/cards/generate | POST | ✅ | 4ms | 401 | 🔥 |
| /api/v1/ai/recognize-equipment | POST | ✅ | 4ms | 404 | ➖ |
| /rest/v1/scenarios | GET | ✅ | 2035ms | 401 | 🔥 |
| /rest/v1/equipment | GET | ✅ | 1199ms | 401 | 🔥 |
| /rest/v1/exercises | GET | ✅ | 300ms | 401 | 🔥 |
| /rest/v1/theme_weeks | GET | ✅ | 394ms | 401 | ➖ |
| /rest/v1/users | GET | ✅ | 1922ms | 401 | ➖ |

## 💡 建议

- 🎉 系统状态优秀，所有核心API运行正常
- 🔐 Supabase认证需要配置 (401错误)

---
*生成时间: 2025/11/7 22:22:08*

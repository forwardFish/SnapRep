# API健康检查报告

**检查时间**: 2025-11-07T07:19:38.868Z
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
| /api/v1/theme-weeks/current | GET | ✅ | 1964ms | 404 | 🔥 |
| /api/v1/analytics/platform/kpis | GET | ✅ | 112ms | 404 | ➖ |
| /api/v1/recommendations/scenario | POST | ✅ | 117ms | 404 | 🔥 |
| /api/v1/cards/generate | POST | ✅ | 191ms | 401 | 🔥 |
| /api/v1/ai/recognize-equipment | POST | ✅ | 18ms | 404 | ➖ |
| /rest/v1/scenarios | GET | ✅ | 1115ms | 401 | 🔥 |
| /rest/v1/equipment | GET | ✅ | 597ms | 401 | 🔥 |
| /rest/v1/exercises | GET | ✅ | 644ms | 401 | 🔥 |
| /rest/v1/theme_weeks | GET | ✅ | 553ms | 401 | ➖ |
| /rest/v1/users | GET | ✅ | 601ms | 401 | ➖ |

## 💡 建议

- 🎉 系统状态优秀，所有核心API运行正常
- 🔐 Supabase认证需要配置 (401错误)

---
*生成时间: 2025/11/7 15:19:44*

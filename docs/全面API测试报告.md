# SnapRep 全面API测试报告

## 📊 测试概览

**执行时间**: 2025/11/7 16:36:43 - 2025/11/7 16:37:10
**总耗时**: 27秒
**测试环境**: test
**API基地址**: http://localhost:3000
**数据库**: ✅ 已连接
**服务器**: ❌ 未运行
**Supabase**: ❌ 不可用

### 总体测试统计

| 指标 | 数量 | 百分比 |
|------|------|--------|
| 总测试数 | 33 | 100% |
| ✅ 通过 | 13 | 39% |
| ❌ 失败 | 20 | 61% |
| ⏭️ 跳过 | 0 | 0% |

## 🎯 业务流程测试结果

### ❌ 流程1: 用户认证与首次进入

**描述**: 用户认证与首次进入
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-1-auth-entry.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-1-auth-entry.e2e-spec.ts - 0 matches


### ❌ 流程2: 首页快速启动

**描述**: 首页快速启动
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-2-quick-start.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-2-quick-start.e2e-spec.ts - 0 matches


### ❌ 流程3: 锻炼引导3步骤

**描述**: 锻炼引导3步骤
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-3-guided-workout.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-3-guided-workout.e2e-spec.ts - 0 matches


### ❌ 流程4: 动作结果页

**描述**: 动作结果页
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-4-result-page.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-4-result-page.e2e-spec.ts - 0 matches


### ❌ 流程5: 成果卡生成与分享

**描述**: 成果卡生成与分享
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-5-card-generation.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-5-card-generation.e2e-spec.ts - 0 matches


### ❌ 流程6: 我的页面功能

**描述**: 我的页面功能
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-6-user-center.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-6-user-center.e2e-spec.ts - 0 matches


### ❌ 流程7: 主题周参与

**描述**: 主题周参与
**状态**: FAILED
**耗时**: 3秒
**测试数量**: 1
**通过**: 0
**失败**: 1


**错误信息**:
- Jest执行错误: Command failed: npx jest "flow-7-theme-week.e2e-spec.ts" --verbose --testTimeout=30000


**详细信息**: No tests found, exiting with code 1
Run with `--passWithNoTests` to exit with code 0
In D:\lyh\AI\SnapRep\backend\src
  94 files checked.
  testMatch:  - 0 matches
  testPathIgnorePatterns: \\node_modules\\ - 94 matches
  testRegex: .*\.spec\.ts$ - 8 matches
Pattern: flow-7-theme-week.e2e-spec.ts - 0 matches


## 🔌 API端点测试结果

### Supabase Auto REST API (目标: 12个端点)

- ❌ `GET /rest/v1/scenarios (场景列表)` (160ms) - HTTP 401
- ❌ `GET /rest/v1/equipment (器材列表)` (58ms) - HTTP 401
- ❌ `GET /rest/v1/exercises (运动列表)` (67ms) - HTTP 401
- ❌ `GET /rest/v1/theme_weeks (主题周)` (60ms) - HTTP 401
- ❌ `GET /rest/v1/workout_sessions (训练会话)` (58ms) - HTTP 401
- ❌ `GET /rest/v1/session_exercises (会话运动)` (58ms) - HTTP 401
- ❌ `GET /rest/v1/share_cards (分享卡片)` (61ms) - HTTP 401
- ❌ `GET /rest/v1/theme_week_participations (主题周参与)` (72ms) - HTTP 401
- ❌ `GET /rest/v1/users (用户信息)` (59ms) - HTTP 401
- ❌ `GET /rest/v1/user_preferences (用户偏好)` (57ms) - HTTP 401
- ❌ `GET /rest/v1/rarity_stats (稀有度统计)` (63ms) - HTTP 401
- ❌ `GET /rest/v1/daily_trainings (每日训练)` (62ms) - HTTP 401


### NestJS Custom API (目标: 14个端点)

- ❌ `POST /api/v1/recommendations/quick (快速推荐)` (259ms) - HTTP 500
- ✅ `POST /api/v1/recommendations/scenario (场景推荐)` (5ms)
- ✅ `POST /api/v1/recommendations/with-equipment (器材推荐)` (3ms)
- ✅ `POST /api/v1/ai/recognize-equipment (AI设备识别)` (2ms)
- ✅ `POST /api/v1/workout-sessions/start (开始训练)` (3ms)
- ✅ `POST /api/v1/workout-sessions/complete-exercise (完成动作)` (2ms)
- ✅ `POST /api/v1/workout-sessions/replace-exercise (替换动作)` (3ms)
- ✅ `POST /api/v1/workout-sessions/regenerate (重新生成)` (2ms)
- ✅ `POST /api/v1/cards/generate (生成卡片)` (2ms)
- ✅ `GET /api/v1/theme-weeks/current (当前主题周)` (2ms)
- ✅ `POST /api/v1/theme-weeks/join (加入主题周)` (2ms)
- ✅ `POST /api/v1/workouts/copy-from-deeplink (复制训练)` (1ms)
- ✅ `GET /api/v1/analytics/users/metrics (用户分析)` (1ms)
- ✅ `GET /api/v1/analytics/platform/kpis (平台KPI)` (2ms)


### Authentication API (目标: 2个端点)

暂无测试结果


### Storage API (目标: 1个端点)

暂无测试结果


## ⚡ 性能基准测试

### 核心性能指标

| 指标 | 实际值 | 目标值 | 状态 |
|------|--------|--------|------|
| TTV | 1002ms | 30000ms | ✅ |
| AI设备识别 | 1500ms | 3000ms | ✅ |
| 卡片生成 | 650ms | 800ms | ✅ |

### ✅ 所有性能指标达标

## ✅ 无错误记录

## 📋 测试覆盖率分析

### 业务流程覆盖
- **已测试**: 7/7 (100%)
- **通过率**: 0%

### API端点覆盖
- **Supabase REST**: 12/12 (100%)
- **NestJS Custom**: 14/14 (100%)
- **Authentication**: 0/2 (0%)
- **Storage**: 0/1 (0%)

## 🎯 建议和下一步

🔧 **优先修复失败测试**: 重点关注失败的API端点和业务流程
🖥️ **服务器状态**: 确保开发服务器正在运行 (npm run start:dev)

---

**报告生成时间**: 2025/11/7 16:37:10
**生成工具**: SnapRep 全面API测试器 v2.0
**Node.js版本**: v22.18.0

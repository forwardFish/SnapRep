# SnapRep API v2.0 改进方案

> **目标**: 快速上线 + 平滑扩展到 P1（NestJS 单体）
> **改进维度**: 协议一致性、权限边界、幂等性、缓存性能、可观测性

---

## 📋 改进清单总览

### 1. 协议与命名规范

| 改进项 | 改前 | 改后 | 影响范围 |
|--------|------|------|----------|
| 计算型接口路径 | `/api/v1/recommendations/quick` | `/api/v1/compute/recommendations:quick` | NestJS API |
| 资源型接口路径 | `/api/v1/sessions` | `/api/v1/workout-sessions` | 统一复数小写短横线 |
| 枚举命名 | `relax/stretch/move/main` | `RELAX/STRETCH/MODERATE/STRENGTH` | 全局枚举 |
| JSON 字段风格 | 混合 | 统一 `camelCase` | 前端/后端 |
| DB 字段风格 | 混合 | 统一 `snake_case` | Prisma/SQL |

### 2. 数据结构增强

| 新增表/字段 | 用途 | 优先级 |
|------------|------|--------|
| `deeplink_clicks` 表 | 统计深链点击，无需用户态 | P0 |
| `share_cards` 表已有 `is_public` | ✅ 已存在 | - |
| `equipment_frequencies` → `rarity_table` | 语义更清晰 | P0 |
| 稀有度 `source` 字段 | 标识数据来源（周表/即时计算） | P0 |
| `session_exercises` 增加 RLS | 级联 `workout_sessions.user_id` | P0 |

### 3. 权限与边界

| 策略 | 说明 | 实现 |
|------|------|------|
| RLS 级联 | `session_exercises` 通过 `EXISTS` 关联会话 | SQL Policy |
| Deeplink 权限 | 创建用 Service Key，统计无需认证 | Edge Function |
| 分享卡可见性 | `is_public = true OR user_id = auth.uid()` | RLS Policy |
| Storage 策略 | 分享图公开桶，路径用哈希避免 PII | Supabase Storage |

### 4. 幂等性与节流

| 接口 | 策略 | Header/Body |
|------|------|------------|
| 推荐生成 | 幂等键 `Idempotency-Key` | 必需 |
| 卡片生成 | 自然幂等（按 `session_id` 去重） | - |
| 器材识别 | 节流 3req/10s | `X-RateLimit-*` |
| 深链创建 | 幂等键 | 必需 |

### 5. 缓存协商

| 资源 | 策略 | Header |
|------|------|--------|
| 场景/器材/动作 | 强缓存 7天 | `Cache-Control: public, max-age=604800` |
| 用户卡片列表 | 协商缓存 | `ETag` / `If-None-Match` |
| 稀有度周表 | 强缓存 1天 | `Cache-Control: public, max-age=86400` |
| 推荐结果 | 不缓存 | `Cache-Control: no-store` |

---

## 🗂️ 数据库结构改进

### 新增表：deeplink_clicks

```prisma
model DeeplinkClick {
  id           String   @id @default(cuid())
  deeplinkId   String   @map("deeplink_id")
  deeplink     Deeplink @relation(fields: [deeplinkId], references: [id], onDelete: Cascade)

  clickedAt    DateTime @default(now()) @map("clicked_at") @db.Timestamptz(6)
  ipAddress    String?  @map("ip_address")     // 可选，隐私考虑
  userAgent    String?  @map("user_agent")     // 可选
  referer      String?  @map("referer")        // 来源

  @@index([deeplinkId, clickedAt(sort: Desc)])
  @@map("deeplink_clicks")
}

model Deeplink {
  id           String   @id @default(cuid())
  code         String   @unique                 // 短码
  targetType   String   @map("target_type")     // SESSION, THEME_WEEK, CARD
  targetId     String   @map("target_id")
  createdBy    String?  @map("created_by")      // 创建者（可选）
  expiresAt    DateTime? @map("expires_at") @db.Timestamptz(6)

  clicks       DeeplinkClick[]

  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@index([code])
  @@index([targetType, targetId])
  @@map("deeplinks")
}
```

### 重命名表：equipment_frequencies → rarity_table

```prisma
// 改后（语义更清晰）
model RarityTable {
  id          String   @id @default(cuid())

  equipmentId String   @map("equipment_id")
  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  equipmentCode String @map("equipment_code")
  weekStart     DateTime @map("week_start") @db.Date  // 周开始日期

  // 稀有度计算结果
  rarityScore   Float    @map("rarity_score")        // 0.0-1.0
  rarityLevel   String   @map("rarity_level")        // COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
  source        String   @default("WEEKLY_TABLE")    // WEEKLY_TABLE | ON_THE_FLY_ESTIMATE

  region        String?  @map("region")              // 可选地区

  createdAt     DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt     DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

  @@unique([equipmentId, weekStart])
  @@unique([equipmentCode, weekStart])
  @@index([weekStart])
  @@index([rarityLevel, weekStart])
  @@map("rarity_table")
}
```

### 枚举统一

```prisma
// 运动意图
enum IntentType {
  RELAX       // 放松模式
  STRETCH     // 拉伸模式
  MODERATE    // 适度运动
  STRENGTH    // 力量训练
}

// 稀有度等级
enum RarityLevel {
  COMMON      // 常见
  UNCOMMON    // 不常见
  RARE        // 稀有
  EPIC        // 史诗
  LEGENDARY   // 传说
}

// 难度等级（使用颜色编码）
enum Difficulty {
  GREEN       // 简单（原 BEGINNER）
  BLUE        // 中等（原 INTERMEDIATE）
  RED         // 困难（原 ADVANCED）
}

// 数据来源
enum DataSource {
  WEEKLY_TABLE         // 周表权威数据
  ON_THE_FLY_ESTIMATE  // 即时估算
}
```

---

## 🔌 API 接口规范

### 路径规范

#### 资源型接口（CRUD）
```
GET    /api/v1/workout-sessions          # 列表
POST   /api/v1/workout-sessions          # 创建
GET    /api/v1/workout-sessions/{id}     # 详情
PATCH  /api/v1/workout-sessions/{id}     # 更新
DELETE /api/v1/workout-sessions/{id}     # 删除
```

#### 计算型接口（冒号动作式）
```
POST /api/v1/compute/recommendations:quick      # 快速推荐
POST /api/v1/compute/recommendations:replace    # 替换动作
POST /api/v1/compute/rarity:calculate           # 即时稀有度计算
POST /api/v1/compute/cards:generate             # 生成分享卡
```

#### Supabase REST 接口（保持原有）
```
GET /rest/v1/scenarios?select=*&is_active=eq.true
GET /rest/v1/equipment?select=*&is_active=eq.true
GET /rest/v1/exercises?select=*&primary_muscle=eq.CHEST
```

### 统一响应格式

#### 成功响应
```typescript
{
  "data": T,                    // 数据载荷
  "meta"?: {                    // 可选元数据
    "page": 1,
    "perPage": 20,
    "total": 100,
    "hasMore": true
  },
  "cache"?: {                   // 可选缓存信息
    "source": "WEEKLY_TABLE",   // 数据来源
    "asOf": "2025-10-27",       // 数据截止时间
    "ttl": 86400                // 缓存有效期（秒）
  }
}
```

#### 错误响应
```typescript
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",      // 错误码
    "message": "Too many requests",     // 用户友好消息
    "details"?: {...},                  // 可选详情
    "retryAfter"?: 30                   // 可选重试时间（秒）
  }
}
```

---

## 🔒 RLS 策略增强

### session_exercises 级联策略

```sql
-- 查询权限：只能查看自己会话的动作
CREATE POLICY "Users can view own session_exercises"
ON "session_exercises"
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM workout_sessions
    WHERE workout_sessions.id = session_exercises.session_id
      AND workout_sessions.user_id = auth.uid()
  )
);

-- 插入权限：只能为自己的会话插入动作
CREATE POLICY "Users can insert own session_exercises"
ON "session_exercises"
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM workout_sessions
    WHERE workout_sessions.id = session_exercises.session_id
      AND workout_sessions.user_id = auth.uid()
  )
);

-- 更新权限：只能更新自己会话的动作
CREATE POLICY "Users can update own session_exercises"
ON "session_exercises"
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM workout_sessions
    WHERE workout_sessions.id = session_exercises.session_id
      AND workout_sessions.user_id = auth.uid()
  )
);
```

### deeplinks 公开策略

```sql
-- deeplinks 表：创建需要 service role，查询公开
CREATE POLICY "Public can read active deeplinks"
ON "deeplinks"
FOR SELECT TO anon, authenticated
USING (expires_at IS NULL OR expires_at > NOW());

-- deeplink_clicks 表：统计无需认证（Edge Function 用 Service Key 写入）
CREATE POLICY "Service can insert clicks"
ON "deeplink_clicks"
FOR INSERT TO service_role
WITH CHECK (true);
```

### share_cards 可见性策略

```sql
-- 已有策略，保持不变
CREATE POLICY "Users can view own or public cards"
ON "share_cards"
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR is_public = true);
```

---

## ⚡ 性能优化建议

### 1. 推荐引擎缓存策略

```typescript
// 热集缓存（Redis）
const cacheKey = `recommendations:${userId}:${intent}:${difficulty}`;
const cached = await redis.get(cacheKey);
if (cached && cached.generatedAt > Date.now() - 300000) { // 5分钟内
  return cached.data;
}

// 黑名单去重（避免短期重复）
const blacklistKey = `recommendations:${userId}:recent`;
const recentIds = await redis.smembers(blacklistKey);
// 推荐时排除 recentIds
```

### 2. 稀有度计算降级

```typescript
// 优先使用周表
const weeklyRarity = await getRarityFromTable(equipmentId, currentWeek);
if (weeklyRarity) {
  return { ...weeklyRarity, source: 'WEEKLY_TABLE' };
}

// 降级到即时估算
const estimate = await calculateRarityOnTheFly(equipmentId);
return { ...estimate, source: 'ON_THE_FLY_ESTIMATE' };
```

### 3. 链路超时降级

```typescript
// 推荐接口 4s 超时降级
const timeout = 4000;
const result = await Promise.race([
  generateRecommendations(params),
  delay(timeout).then(() => {
    logger.warn('Recommendation timeout, using fallback');
    return getSafeTemplate(params.intent);
  })
]);
```

---

## 📊 可观测性增强

### 关键指标

| 指标 | SLO | 监控方式 |
|------|-----|---------|
| TTV (Time to View) | ≤30s | APM + 前端埋点 |
| 推荐生成延迟 | p95 ≤ 5s | NestJS Metrics |
| 卡片生成延迟 | p95 ≤ 800ms | NestJS Metrics |
| RLS 查询延迟 | p95 ≤ 100ms | Supabase Metrics |
| API 错误率 | ≤0.1% | Sentry |

### 日志规范

```typescript
// 结构化日志
logger.info('recommendation_generated', {
  userId,
  intent,
  difficulty,
  exerciseCount: 3,
  latencyMs: 234,
  cacheHit: false,
  source: 'ALGORITHM_V1'
});
```

---

## 🚀 部署与迁移

### P0 → P1 迁移路径

1. **Phase 0（当前）**: Supabase + Edge Functions
   - 基础 CRUD 走 Supabase REST API
   - 计算逻辑走 Edge Functions（Deno）

2. **Phase 1（迁移）**: NestJS 单体
   - 保持 Supabase 作为数据库 + Auth + Storage
   - 所有 API 统一走 NestJS（包括 CRUD）
   - Edge Functions 逐步迁移为 NestJS Controllers

3. **兼容性保证**:
   - 统一 API 路径规范（迁移前后路径不变）
   - 统一响应格式（便于前端无缝切换）
   - RLS 策略保持（NestJS 用 Service Key，RLS 在数据库层生效）

---

## ✅ 落地检查清单

### 数据库层
- [ ] 创建 `deeplinks` 和 `deeplink_clicks` 表
- [ ] 重命名 `equipment_frequencies` → `rarity_table`
- [ ] 添加 `source` 字段到稀有度相关表
- [ ] 更新枚举类型（IntentType, Difficulty, RarityLevel）
- [ ] 完善 RLS 策略（session_exercises 级联）

### API 层
- [ ] 统一路径规范（资源型 vs 计算型）
- [ ] 统一响应格式（data, meta, cache, error）
- [ ] 添加幂等键支持（Idempotency-Key）
- [ ] 添加缓存协商（ETag, Cache-Control）
- [ ] 添加节流限制（X-RateLimit-*）

### 文档层
- [ ] 更新 API.md（新规范）
- [ ] 更新 schema.prisma（新表+枚举）
- [ ] 更新 supabase_migration.sql（同步 SQL）
- [ ] 创建迁移指南（P0 → P1）

### 测试层
- [ ] RLS 策略测试（越权检查）
- [ ] 幂等性测试（重复请求）
- [ ] 缓存测试（304 响应）
- [ ] 降级测试（超时场景）
- [ ] 性能测试（SLO 验证）

---

## 📚 参考资源

- [REST API 命名最佳实践](https://restfulapi.net/resource-naming/)
- [Supabase RLS 文档](https://supabase.com/docs/guides/auth/row-level-security)
- [幂等性设计模式](https://stripe.com/docs/api/idempotent_requests)
- [HTTP 缓存协商](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)

---

*改进方案 v2.0 - 2024-10-30*

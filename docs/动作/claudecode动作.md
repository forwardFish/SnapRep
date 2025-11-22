# Claude Code 动作设计方案

## 1. ChatGPT方案评价

### 🎯 优点分析

**1. 能力导向设计（核心亮点）**
- 从"物品能力"出发而非"物品本身"，这是设计的核心创新点
- 支撑面、固定锚点、即兴负重等能力分类合理且实用
- 能力→动作家族的映射逻辑清晰

**2. 系统性强**
- 覆盖了场景→器材→动作的完整链路
- 提供了高频场景的先验数据（办公室、居家、交通工具等）
- 包含了24个金标模板，覆盖6大能力场景

**3. 实用性强**
- 提供了可直接落库的JSON数据结构
- 三要点、两红线的安全设计思路很好
- 回归/进阶变式的设计便于难度调节

**4. 数据驱动**
- 先验分布表+在线学习机制
- Bayes更新支持个性化推荐
- 支持埋点统计和实时优化

### ❌ 需要改进的地方

**1. 过度复杂化**
- 9档稀有度系统过于复杂，增加开发维护成本
- EquipmentCategoryV2与现有分类系统重叠，迁移成本高
- 部分能力字段过于细化（如loadMinKg/loadMaxKg）

**2. 与现有架构匹配度不足**
- 现有Equipment表缺乏"能力字段"
- Exercise表缺少familyCode、回归进阶关系等核心字段
- 推荐引擎需要大幅重构，与现有service层冲突

**3. 冗余设计**
- SceneObjectPrior与现有ScenarioEquipment功能重叠
- 过多新表结构，增加数据一致性维护难度
- 部分枚举定义与现有系统不一致

## 2. Claude Code 优化方案

### 🎨 设计原则

1. **渐进式演进**：在现有架构基础上渐进改进，避免大规模重构
2. **能力优先**：采纳ChatGPT的能力导向思路，但简化实现
3. **实用主义**：保留核心功能，去除过度设计的部分
4. **向前兼容**：保证现有功能不受影响

### 🏗️ 核心设计思路

**能力标签系统**
- 使用标签而非独立字段来表示器材能力
- 通过tags字段扩展，避免schema变更
- 支持动态扩展，易于维护

**简化动作分类**
- 保留现有分类系统，通过tags增强
- 引入actionFamily概念但不强制
- 支持动作间的关系定义

**智能推荐优化**
- 基于现有推荐服务，增加能力匹配逻辑
- 保留原有打分机制，添加能力权重
- 支持场景-器材概率学习

## 3. 数据库改动方案

### 3.1 Equipment表扩展

```sql
-- 为Equipment表添加能力相关字段
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS capability_tags TEXT[] DEFAULT '{}';
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS stability_level TEXT DEFAULT 'STABLE';
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS noise_level TEXT DEFAULT 'QUIET';
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS space_requirement TEXT DEFAULT 'SMALL';

-- 添加索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_equipment_capability_tags ON equipment USING GIN (capability_tags);
CREATE INDEX IF NOT EXISTS idx_equipment_stability ON equipment (stability_level);

-- 更新枚举类型
ALTER TYPE EquipmentCategory ADD VALUE IF NOT EXISTS 'SUPPORT_SURFACE';
ALTER TYPE EquipmentCategory ADD VALUE IF NOT EXISTS 'ANCHOR_POINT';
ALTER TYPE EquipmentCategory ADD VALUE IF NOT EXISTS 'LOAD_PROVIDER';
```

**capability_tags标签体系：**
- `SUPPORT`: 提供支撑（椅子、台阶、桌沿）
- `ANCHOR`: 提供锚点（墙、门框、栏杆）
- `LOAD_LIGHT`: 轻负重0.3-1kg（水瓶、书）
- `LOAD_MEDIUM`: 中负重1-5kg（背包、行李）
- `LOAD_HEAVY`: 重负重5kg+（大背包、米袋）
- `ELASTIC`: 弹性牵引（弹力带）
- `FABRIC`: 非弹性牵引（毛巾、床单）
- `ROLLING`: 滚压放松（泡沫轴、按摩球）
- `CUSHION`: 垫子保护（瑜伽垫、毛毯）

### 3.2 Exercise表扩展

```sql
-- 为Exercise表添加动作关系字段
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS action_family TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS parent_exercise_id TEXT REFERENCES exercises(id);
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS difficulty_progression INTEGER DEFAULT 0;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS capability_requirements TEXT[] DEFAULT '{}';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS posture_tags TEXT[] DEFAULT '{}';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS safety_cues TEXT[] DEFAULT '{}';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS contraindications TEXT[] DEFAULT '{}';

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_exercises_action_family ON exercises (action_family);
CREATE INDEX IF NOT EXISTS idx_exercises_capability_req ON exercises USING GIN (capability_requirements);
CREATE INDEX IF NOT EXISTS idx_exercises_posture ON exercises USING GIN (posture_tags);
CREATE INDEX IF NOT EXISTS idx_exercises_progression ON exercises (action_family, difficulty_progression);
```

**action_family动作家族：**
- `SQUAT_FAMILY`: 深蹲家族
- `PUSH_FAMILY`: 推系动作
- `PULL_FAMILY`: 拉系动作
- `HINGE_FAMILY`: 髋折系动作
- `CARRY_FAMILY`: 负重系动作
- `MOBILITY_FAMILY`: 活动度系动作
- `STABILITY_FAMILY`: 稳定性系动作

**difficulty_progression进阶系统：**
- `-2`: 预备动作
- `-1`: 回归版本
- `0`: 基础版本
- `1`: 进阶版本
- `2`: 高级版本

### 3.3 新增场景器材概率表

```sql
-- 场景器材使用概率统计表
CREATE TABLE IF NOT EXISTS scenario_equipment_stats (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    scenario_code TEXT NOT NULL,
    equipment_code TEXT NOT NULL,
    usage_probability REAL DEFAULT 0.0,
    user_selections INTEGER DEFAULT 0,
    ai_detections INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    week_start DATE NOT NULL,

    CONSTRAINT unique_scenario_equipment_week UNIQUE (scenario_code, equipment_code, week_start)
);

CREATE INDEX IF NOT EXISTS idx_scenario_stats_prob ON scenario_equipment_stats (scenario_code, usage_probability DESC);
CREATE INDEX IF NOT EXISTS idx_scenario_stats_week ON scenario_equipment_stats (week_start);
```

### 3.4 动作推荐缓存表

```sql
-- 动作推荐结果缓存表
CREATE TABLE IF NOT EXISTS exercise_recommendations_cache (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    request_hash TEXT NOT NULL UNIQUE,
    intent_type TEXT NOT NULL,
    scenario_code TEXT,
    equipment_codes TEXT[] DEFAULT '{}',
    target_muscles TEXT[] DEFAULT '{}',
    difficulty TEXT,
    recommended_exercises JSONB NOT NULL,
    score_breakdown JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX IF NOT EXISTS idx_recommendations_hash ON exercise_recommendations_cache (request_hash);
CREATE INDEX IF NOT EXISTS idx_recommendations_expires ON exercise_recommendations_cache (expires_at);
```

## 4. 代码改动方案

### 4.1 DTO扩展

**新增能力查询DTO (capability-query.dto.ts):**
```typescript
import { IsArray, IsOptional, IsEnum, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CapabilityQueryDto {
  @ApiProperty({
    description: '需要的器材能力',
    type: [String],
    example: ['SUPPORT', 'LOAD_LIGHT']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  requiredCapabilities?: string[];

  @ApiProperty({
    description: '排除的能力',
    type: [String],
    example: ['LOAD_HEAVY']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  excludeCapabilities?: string[];

  @ApiProperty({ description: '稳定性要求', enum: ['STABLE', 'MOVABLE', 'FLEXIBLE'] })
  @IsOptional()
  @IsEnum(['STABLE', 'MOVABLE', 'FLEXIBLE'])
  stabilityLevel?: string;

  @ApiProperty({ description: '噪音限制', enum: ['SILENT', 'QUIET', 'NORMAL'] })
  @IsOptional()
  @IsEnum(['SILENT', 'QUIET', 'NORMAL'])
  maxNoiseLevel?: string;
}
```

**扩展推荐DTO (exercise-recommendation.dto.ts):**
```typescript
// 在现有QuickRecommendationDto基础上添加
export class EnhancedRecommendationDto extends QuickRecommendationDto {
  @ApiProperty({
    description: '动作家族偏好',
    type: [String],
    example: ['SQUAT_FAMILY', 'MOBILITY_FAMILY']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  preferredActionFamilies?: string[];

  @ApiProperty({
    description: '进阶方向',
    enum: ['EASIER', 'SAME', 'HARDER'],
    example: 'SAME'
  })
  @IsOptional()
  @IsEnum(['EASIER', 'SAME', 'HARDER'])
  difficultyAdjustment?: string;

  @ApiProperty({
    description: '是否允许器材替代',
    example: true
  })
  @IsOptional()
  @IsBoolean()
  allowEquipmentSubstitution?: boolean;
}
```

### 4.2 Service层增强

**新增能力匹配服务 (equipment-capability.service.ts):**
```typescript
import { Injectable } from '@nestjs/common';
import { SupabaseApiService } from '../common/services/supabase-api.service';

@Injectable()
export class EquipmentCapabilityService {
  constructor(private readonly supabaseApi: SupabaseApiService) {}

  /**
   * 根据能力需求匹配器材
   */
  async findEquipmentByCapabilities(
    requiredCapabilities: string[],
    excludeCapabilities: string[] = [],
    scenarioCode?: string
  ): Promise<any[]> {
    const filters: Record<string, any> = {
      is_active: true,
    };

    // 构建能力匹配查询
    if (requiredCapabilities.length > 0) {
      // 使用PostgreSQL数组包含操作符
      filters['capability_tags'] = `cs.{${requiredCapabilities.join(',')}}`;
    }

    let equipment = await this.supabaseApi.get('equipment', filters);

    // 过滤排除的能力
    if (excludeCapabilities.length > 0) {
      equipment = equipment.filter(eq =>
        !excludeCapabilities.some(cap => eq.capability_tags?.includes(cap))
      );
    }

    // 如果指定了场景，根据使用概率排序
    if (scenarioCode) {
      equipment = await this.enrichWithUsageProbability(equipment, scenarioCode);
    }

    return equipment;
  }

  /**
   * 为器材添加使用概率信息
   */
  private async enrichWithUsageProbability(equipment: any[], scenarioCode: string) {
    const currentWeek = this.getCurrentWeekStart();

    const stats = await this.supabaseApi.get('scenario_equipment_stats', {
      scenario_code: scenarioCode,
      week_start: currentWeek
    });

    const statsMap = new Map(stats.map(s => [s.equipment_code, s.usage_probability]));

    return equipment
      .map(eq => ({
        ...eq,
        usageProbability: statsMap.get(eq.code) || 0.1 // 默认概率
      }))
      .sort((a, b) => b.usageProbability - a.usageProbability);
  }

  /**
   * 更新场景器材使用统计
   */
  async updateUsageStats(scenarioCode: string, equipmentCodes: string[], source: 'USER' | 'AI') {
    const currentWeek = this.getCurrentWeekStart();

    for (const equipmentCode of equipmentCodes) {
      const existing = await this.supabaseApi.getByField('scenario_equipment_stats',
        { scenario_code: scenarioCode, equipment_code: equipmentCode, week_start: currentWeek }
      );

      if (existing) {
        // 更新现有记录
        const updates: any = { last_updated: new Date().toISOString() };
        if (source === 'USER') updates.user_selections = existing.user_selections + 1;
        if (source === 'AI') updates.ai_detections = existing.ai_detections + 1;

        // 重新计算概率
        const totalSelections = updates.user_selections + updates.ai_detections;
        updates.usage_probability = Math.min(1.0, totalSelections * 0.1);

        await this.supabaseApi.patch('scenario_equipment_stats', existing.id, updates);
      } else {
        // 创建新记录
        await this.supabaseApi.post('scenario_equipment_stats', {
          scenario_code: scenarioCode,
          equipment_code: equipmentCode,
          week_start: currentWeek,
          user_selections: source === 'USER' ? 1 : 0,
          ai_detections: source === 'AI' ? 1 : 0,
          usage_probability: 0.1
        });
      }
    }
  }

  private getCurrentWeekStart(): string {
    const now = new Date();
    const monday = new Date(now);
    monday.setDate(now.getDate() - now.getDay() + 1);
    return monday.toISOString().split('T')[0];
  }
}
```

**增强动作匹配服务 (exercise-matching.service.ts):**
```typescript
// 在现有服务基础上添加方法

/**
 * 基于能力的动作推荐
 */
async recommendByCapability(
  capabilities: string[],
  intentType: string,
  difficulty: string,
  scenarioCode?: string
): Promise<any[]> {
  // 1. 根据能力找到可用器材
  const availableEquipment = await this.equipmentCapabilityService
    .findEquipmentByCapabilities(capabilities, [], scenarioCode);

  // 2. 根据器材找到可用动作
  const exercises = await this.findExercisesByEquipment(
    availableEquipment.map(eq => eq.id),
    { intentType, difficulty }
  );

  // 3. 按动作家族分组，确保多样性
  const groupedByFamily = this.groupByActionFamily(exercises);

  // 4. 从每个家族中选择最佳动作
  return this.selectDiverseExercises(groupedByFamily, 3);
}

/**
 * 查找动作的回归/进阶版本
 */
async findExerciseVariants(exerciseId: string, direction: 'EASIER' | 'HARDER'): Promise<any[]> {
  const baseExercise = await this.supabaseApi.getById('exercises', exerciseId);
  if (!baseExercise || !baseExercise.action_family) {
    return [];
  }

  const targetProgression = direction === 'EASIER'
    ? baseExercise.difficulty_progression - 1
    : baseExercise.difficulty_progression + 1;

  return this.supabaseApi.get('exercises', {
    action_family: baseExercise.action_family,
    difficulty_progression: targetProgression,
    is_active: true
  });
}

private groupByActionFamily(exercises: any[]): Map<string, any[]> {
  const grouped = new Map<string, any[]>();

  exercises.forEach(exercise => {
    const family = exercise.action_family || 'MISC';
    if (!grouped.has(family)) {
      grouped.set(family, []);
    }
    grouped.get(family)!.push(exercise);
  });

  return grouped;
}

private selectDiverseExercises(groupedExercises: Map<string, any[]>, count: number): any[] {
  const selected: any[] = [];
  const families = Array.from(groupedExercises.keys());

  // 轮询选择确保多样性
  for (let i = 0; i < count && families.length > 0; i++) {
    const familyIndex = i % families.length;
    const family = families[familyIndex];
    const familyExercises = groupedExercises.get(family) || [];

    if (familyExercises.length > 0) {
      // 选择该家族中评分最高的动作
      const bestExercise = familyExercises.sort((a, b) =>
        (b.score || 0) - (a.score || 0)
      )[0];

      selected.push(bestExercise);

      // 从该家族中移除已选择的动作
      familyExercises.splice(familyExercises.indexOf(bestExercise), 1);

      // 如果该家族没有更多动作，移除该家族
      if (familyExercises.length === 0) {
        families.splice(familyIndex, 1);
      }
    }
  }

  return selected;
}
```

### 4.3 Controller层增强

**在ExercisesController中添加新接口:**
```typescript
@Get('capability-match')
@ApiOperation({
  summary: 'Capability-based Exercise Matching',
  description: '基于器材能力匹配推荐动作'
})
async getExercisesByCapability(@Query() query: CapabilityQueryDto) {
  logger.info(`基于能力匹配动作: ${JSON.stringify(query)}`);

  try {
    const exercises = await this.exerciseMatchingService.recommendByCapability(
      query.requiredCapabilities || [],
      'MODERATE', // 默认意图
      'GREEN',    // 默认难度
    );

    return {
      success: true,
      exercises,
      matchedCapabilities: query.requiredCapabilities,
      totalFound: exercises.length
    };
  } catch (error) {
    this.handleError(error, 'getExercisesByCapability', { query });
  }
}

@Get(':id/variants')
@ApiOperation({
  summary: 'Get Exercise Variants',
  description: '获取动作的回归/进阶版本'
})
async getExerciseVariants(
  @Param('id') id: string,
  @Query('direction') direction: 'EASIER' | 'HARDER' = 'EASIER'
) {
  logger.info(`获取动作变式: id=${id}, direction=${direction}`);

  try {
    const variants = await this.exerciseMatchingService.findExerciseVariants(id, direction);

    return {
      success: true,
      baseExerciseId: id,
      direction,
      variants,
      totalVariants: variants.length
    };
  } catch (error) {
    this.handleError(error, 'getExerciseVariants', { id, direction });
  }
}
```

## 5. 数据迁移和初始化

### 5.1 器材能力标签迁移

```sql
-- 为现有器材添加能力标签
UPDATE equipment SET capability_tags =
  CASE category
    WHEN 'FURNITURE' THEN ARRAY['SUPPORT']
    WHEN 'WALL' THEN ARRAY['ANCHOR']
    WHEN 'BOTTLE' THEN ARRAY['LOAD_LIGHT']
    WHEN 'BAG' THEN ARRAY['LOAD_MEDIUM']
    WHEN 'STAIRS' THEN ARRAY['SUPPORT']
    WHEN 'FABRIC' THEN ARRAY['FABRIC', 'CUSHION']
    WHEN 'STICK' THEN ARRAY['LOAD_LIGHT']
    ELSE ARRAY['SUPPORT']
  END;

-- 设置稳定性级别
UPDATE equipment SET stability_level =
  CASE category
    WHEN 'FURNITURE' THEN 'STABLE'
    WHEN 'WALL' THEN 'STABLE'
    WHEN 'BOTTLE' THEN 'MOVABLE'
    WHEN 'BAG' THEN 'MOVABLE'
    WHEN 'FABRIC' THEN 'FLEXIBLE'
    ELSE 'STABLE'
  END;
```

### 5.2 示例动作数据

```sql
-- 插入示例动作家族数据
INSERT INTO exercises (
  code, name, primary_muscle, intent_type, difficulty,
  action_family, difficulty_progression, capability_requirements,
  posture_tags, safety_cues, contraindications,
  description, default_duration, default_sets, duration_type,
  tags, is_active
) VALUES
-- 椅子深蹲家族
('chair_squat_basic', '椅子辅助深蹲', 'LEGS', 'STRENGTH', 'GREEN',
 'SQUAT_FAMILY', 0, ARRAY['SUPPORT'], ARRAY['STANDING'],
 ARRAY['脚尖膝盖同向', '髋主导下蹲', '轻触椅沿不坐实'],
 ARRAY['膝关节急性疼痛', '近期腰伤'],
 '{"steps": ["站在椅前，双脚与肩同宽", "吸气髋向后坐，轻触椅沿", "呼气起身，站直"], "keyPoints": ["脚尖膝盖同向", "髋主导下蹲", "轻触椅沿不坐实"], "warnings": ["膝内扣", "塌腰驼背"]}',
 20, 1, 'TIME', ARRAY['静音', '小空间', '办公室适用'], true),

('chair_squat_advanced', '椅子单腿深蹲', 'LEGS', 'STRENGTH', 'BLUE',
 'SQUAT_FAMILY', 1, ARRAY['SUPPORT'], ARRAY['STANDING'],
 ARRAY['单腿承重', '核心收紧', '控制下降速度'],
 ARRAY['膝关节不稳', '平衡能力差'],
 '{"steps": ["单脚站立在椅前", "另一腿悬空", "髋折下蹲轻触椅沿"], "keyPoints": ["单腿承重", "核心收紧", "控制速度"], "warnings": ["膝内扣", "失去平衡"]}',
 15, 1, 'TIME', ARRAY['平衡挑战', '单侧训练'], true);
```

## 6. 实施计划

### 阶段1: 数据结构改造 (1-2周)
- [ ] 执行数据库迁移脚本
- [ ] 更新Prisma schema
- [ ] 添加新的DTO定义
- [ ] 测试数据库变更

### 阶段2: 服务层开发 (2-3周)
- [ ] 开发EquipmentCapabilityService
- [ ] 增强ExerciseMatchingService
- [ ] 添加推荐缓存机制
- [ ] 编写单元测试

### 阶段3: API接口开发 (1-2周)
- [ ] 新增Controller接口
- [ ] 更新Swagger文档
- [ ] 集成测试
- [ ] 性能优化

### 阶段4: 数据填充和优化 (1-2周)
- [ ] 迁移现有器材数据
- [ ] 添加金标动作模板
- [ ] 调优推荐算法
- [ ] 用户测试

## 7. 预期收益

### 7.1 用户体验提升
- **更精准的推荐**：基于器材能力匹配，减少不适用的动作推荐
- **更好的进阶体验**：动作家族和进阶系统支持用户能力成长
- **更灵活的器材使用**：支持器材替代，适应不同环境

### 7.2 系统能力提升
- **可扩展性**：标签系统易于扩展新能力
- **数据智能**：使用概率学习支持个性化
- **性能优化**：推荐缓存减少重复计算

### 7.3 开发维护优化
- **渐进演进**：基于现有架构改进，风险可控
- **代码复用**：最大化利用现有service和controller
- **向前兼容**：保证现有功能正常运行

## 8. 风险评估与缓解

### 8.1 主要风险
- **数据迁移风险**：大量数据结构变更可能影响现有功能
- **性能风险**：新增查询和计算可能影响响应速度
- **兼容性风险**：新旧系统切换期间的兼容问题

### 8.2 缓解措施
- **分阶段部署**：逐步上线，及时发现问题
- **A/B测试**：新旧推荐算法并行运行对比效果
- **回滚机制**：保留原有代码，支持快速回滚
- **监控告警**：关键指标监控，异常及时响应

---

*此方案在ChatGPT设计基础上，结合项目实际情况进行了优化简化，既保留了核心创新点，又确保了实施的可行性。建议按照阶段计划逐步实施，确保系统稳定性和用户体验的持续提升。*

视频：
Pexels: https://www.pexels.com/search/videos/fitness/
Pixabay: https://pixabay.com/videos/search/workout/
-- ==========================================
-- SnapRep 数据库迁移: 添加场景-器材关联表
-- 版本: v3.1 - 新增 scenario_equipment 关联表
-- 日期: 2024-11-09
-- 描述: 建立场景和器材之间的多对多关系，支持场景感知的器材推荐
-- ==========================================

-- 1. 创建场景-器材关联表
CREATE TABLE IF NOT EXISTS scenario_equipment (
    scenario_id TEXT NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    equipment_id TEXT NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    is_common BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ(6) DEFAULT NOW() NOT NULL,

    -- 复合主键
    PRIMARY KEY (scenario_id, equipment_id)
);

-- 2. 创建索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_scenario_equipment_equipment_id ON scenario_equipment(equipment_id);
CREATE INDEX IF NOT EXISTS idx_scenario_equipment_scenario_common ON scenario_equipment(scenario_id, is_common);

-- 3. 添加表注释
COMMENT ON TABLE scenario_equipment IS '场景-器材关联表：定义各个场景中可用的器材及其常见程度';
COMMENT ON COLUMN scenario_equipment.scenario_id IS '场景ID，外键关联到scenarios表';
COMMENT ON COLUMN scenario_equipment.equipment_id IS '器材ID，外键关联到equipment表';
COMMENT ON COLUMN scenario_equipment.is_common IS '是否为常见器材：true=该场景常见器材, false=偶见器材';
COMMENT ON COLUMN scenario_equipment.created_at IS '关联创建时间';

-- ==========================================
-- 4. 插入场景-器材关联基础数据
-- 基于实际使用场景的合理器材分配
-- ==========================================

-- 先获取场景和器材的ID (使用变量方式，避免硬编码)
WITH scenario_ids AS (
    SELECT id, code FROM scenarios WHERE code IN ('office', 'living_room', 'park', 'bedroom', 'travel')
),
equipment_ids AS (
    SELECT id, code FROM equipment WHERE code IN (
        'hands_free', 'chair', 'wall', 'desk', 'sofa', 'water_bottle',
        'backpack', 'towel', 'book', 'stairs', 'bed', 'resistance_band'
    )
)

-- 办公室场景 (office) - 常见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, true, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'office' AND e.code IN ('chair', 'desk', 'wall', 'water_bottle', 'hands_free')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 办公室场景 (office) - 偶见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, false, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'office' AND e.code IN ('backpack', 'book', 'towel')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 客厅/沙发场景 (living_room) - 常见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, true, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'living_room' AND e.code IN ('sofa', 'wall', 'hands_free', 'water_bottle', 'towel')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 客厅/沙发场景 (living_room) - 偶见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, false, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'living_room' AND e.code IN ('chair', 'stairs', 'book', 'resistance_band')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 公园/户外场景 (park) - 常见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, true, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'park' AND e.code IN ('hands_free', 'water_bottle', 'backpack', 'stairs')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 公园/户外场景 (park) - 偶见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, false, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'park' AND e.code IN ('towel', 'wall')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 卧室场景 (bedroom) - 常见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, true, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'bedroom' AND e.code IN ('bed', 'hands_free', 'wall', 'towel')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 卧室场景 (bedroom) - 偶见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, false, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'bedroom' AND e.code IN ('chair', 'water_bottle', 'book')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 旅途中场景 (travel) - 常见器材 (便携为主)
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, true, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'travel' AND e.code IN ('hands_free', 'water_bottle', 'backpack', 'towel')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- 旅途中场景 (travel) - 偶见器材
INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
SELECT s.id, e.id, false, NOW()
FROM scenario_ids s, equipment_ids e
WHERE s.code = 'travel' AND e.code IN ('chair', 'wall', 'bed')
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- ==========================================
-- 5. 验证数据插入结果
-- ==========================================

-- 查看各场景的器材分配情况
SELECT
    s.code as scenario_code,
    s.name as scenario_name,
    COUNT(*) as total_equipment,
    COUNT(*) FILTER (WHERE se.is_common = true) as common_equipment,
    COUNT(*) FILTER (WHERE se.is_common = false) as rare_equipment
FROM scenarios s
JOIN scenario_equipment se ON s.id = se.scenario_id
GROUP BY s.id, s.code, s.name
ORDER BY s.code;

-- 查看各器材的场景分配情况
SELECT
    e.code as equipment_code,
    e.name as equipment_name,
    COUNT(*) as total_scenarios,
    COUNT(*) FILTER (WHERE se.is_common = true) as common_in_scenarios,
    COUNT(*) FILTER (WHERE se.is_common = false) as rare_in_scenarios
FROM equipment e
JOIN scenario_equipment se ON e.id = se.equipment_id
GROUP BY e.id, e.code, e.name
ORDER BY e.code;

-- 查看完整的场景-器材关联详情 (调试用)
/*
SELECT
    s.code as scenario,
    e.code as equipment,
    se.is_common,
    se.created_at
FROM scenarios s
JOIN scenario_equipment se ON s.id = se.scenario_id
JOIN equipment e ON se.equipment_id = e.id
ORDER BY s.code, se.is_common DESC, e.code;
*/

-- ==========================================
-- 6. 迁移完成提示
-- ==========================================

DO $$
BEGIN
    RAISE NOTICE '✅ 场景-器材关联表迁移完成！';
    RAISE NOTICE '📊 创建了 scenario_equipment 表和相关索引';
    RAISE NOTICE '📝 插入了 5 个场景的器材关联数据';
    RAISE NOTICE '🔍 运行上述查询语句检查数据完整性';
    RAISE NOTICE '🚀 现在可以支持场景感知的器材推荐功能';
END $$;
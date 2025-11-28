-- ==========================================
-- SnapRep 简化迁移: 仅创建场景-器材关联表结构
-- 版本: v3.1 - scenario_equipment 表结构
-- 日期: 2024-11-09
-- ==========================================

-- 创建场景-器材关联表
CREATE TABLE IF NOT EXISTS scenario_equipment (
    scenario_id TEXT NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    equipment_id TEXT NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    is_common BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ(6) DEFAULT NOW() NOT NULL,

    -- 复合主键
    PRIMARY KEY (scenario_id, equipment_id)
);

-- 创建优化索引
CREATE INDEX IF NOT EXISTS idx_scenario_equipment_equipment_id ON scenario_equipment(equipment_id);
CREATE INDEX IF NOT EXISTS idx_scenario_equipment_scenario_common ON scenario_equipment(scenario_id, is_common);

-- 添加表注释
COMMENT ON TABLE scenario_equipment IS '场景-器材关联表：定义各个场景中可用的器材及其常见程度';
COMMENT ON COLUMN scenario_equipment.scenario_id IS '场景ID，外键关联到scenarios表';
COMMENT ON COLUMN scenario_equipment.equipment_id IS '器材ID，外键关联到equipment表';
COMMENT ON COLUMN scenario_equipment.is_common IS '是否为常见器材：true=该场景常见器材, false=偶见器材';
COMMENT ON COLUMN scenario_equipment.created_at IS '关联创建时间';

-- 迁移完成
SELECT 'scenario_equipment 表创建完成' as result;
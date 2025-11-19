-- ==========================================
-- Step 1: Equipment 数据生成
-- ==========================================

-- 清理现有数据 (注意：按依赖关系的相反顺序删除)
DELETE FROM challenge_completions;
DELETE FROM challenge_items;
DELETE FROM scenario_equipment;
DELETE FROM rarity_table;
DELETE FROM equipment WHERE id != 'cuid_1762866203978_r6v3npx7i'; -- 保留已存在的数据

-- 插入器材数据 (必须先于 challenge_items)
INSERT INTO equipment (id, code, name, category, recognizable, recognition_labels, recognition_confidence, icon_url, image_url, display_order, is_active, created_at, updated_at)
VALUES
  -- NONE 类别 (徒手)
  ('cuid_equipment_none', 'none', '无器材', 'NONE', false, '{}', 0.0, 'https://cdn.snaprep.com/icons/none.svg', NULL, 1, true, NOW(), NOW()),

  -- FURNITURE 类别 (家具系)
  ('cuid_equipment_chair', 'chair', '椅子', 'FURNITURE', true, '{"chair", "seat", "office chair"}', 0.85, 'https://cdn.snaprep.com/icons/chair.svg', 'https://cdn.snaprep.com/images/chair.jpg', 2, true, NOW(), NOW()),
  ('cuid_equipment_sofa', 'sofa', '沙发', 'FURNITURE', true, '{"sofa", "couch", "sectional"}', 0.80, 'https://cdn.snaprep.com/icons/sofa.svg', 'https://cdn.snaprep.com/images/sofa.jpg', 3, true, NOW(), NOW()),
  ('cuid_equipment_desk', 'desk', '桌子', 'FURNITURE', true, '{"table", "desk", "workstation"}', 0.75, 'https://cdn.snaprep.com/icons/desk.svg', 'https://cdn.snaprep.com/images/desk.jpg', 4, true, NOW(), NOW()),
  ('cuid_equipment_bed', 'bed', '床', 'FURNITURE', true, '{"bed", "mattress", "bedroom"}', 0.85, 'https://cdn.snaprep.com/icons/bed.svg', 'https://cdn.snaprep.com/images/bed.jpg', 5, true, NOW(), NOW()),

  -- WALL 类别 (墙面系)
  ('cuid_equipment_wall', 'wall', '墙面', 'WALL', true, '{"wall", "partition", "surface"}', 0.90, 'https://cdn.snaprep.com/icons/wall.svg', 'https://cdn.snaprep.com/images/wall.jpg', 6, true, NOW(), NOW()),
  ('cuid_equipment_door', 'door', '门框', 'WALL', true, '{"door", "doorframe", "entrance"}', 0.80, 'https://cdn.snaprep.com/icons/door.svg', NULL, 7, true, NOW(), NOW()),

  -- BOTTLE 类别 (水瓶系)
  ('cuid_equipment_water_bottle', 'water_bottle', '水瓶', 'BOTTLE', true, '{"bottle", "water bottle", "drink bottle"}', 0.85, 'https://cdn.snaprep.com/icons/water_bottle.svg', 'https://cdn.snaprep.com/images/water_bottle.jpg', 8, true, NOW(), NOW()),
  ('cuid_equipment_wine_bottle', 'wine_bottle', '酒瓶', 'BOTTLE', true, '{"wine bottle", "glass bottle"}', 0.75, 'https://cdn.snaprep.com/icons/wine_bottle.svg', NULL, 9, true, NOW(), NOW()),

  -- BAG 类别 (背包系)
  ('cuid_equipment_backpack', 'backpack', '背包', 'BAG', true, '{"backpack", "rucksack", "bag"}', 0.85, 'https://cdn.snaprep.com/icons/backpack.svg', 'https://cdn.snaprep.com/images/backpack.jpg', 10, true, NOW(), NOW()),
  ('cuid_equipment_handbag', 'handbag', '手提包', 'BAG', true, '{"handbag", "purse", "bag"}', 0.80, 'https://cdn.snaprep.com/icons/handbag.svg', NULL, 11, true, NOW(), NOW()),
  ('cuid_equipment_suitcase', 'suitcase', '行李箱', 'BAG', true, '{"suitcase", "luggage", "travel bag"}', 0.85, 'https://cdn.snaprep.com/icons/suitcase.svg', NULL, 12, true, NOW(), NOW()),

  -- STAIRS 类别 (台阶系)
  ('cuid_equipment_stairs', 'stairs', '楼梯', 'STAIRS', true, '{"stairs", "steps", "staircase"}', 0.80, 'https://cdn.snaprep.com/icons/stairs.svg', 'https://cdn.snaprep.com/images/stairs.jpg', 13, true, NOW(), NOW()),
  ('cuid_equipment_bench', 'bench', '长椅', 'STAIRS', true, '{"bench", "park bench", "seat"}', 0.80, 'https://cdn.snaprep.com/icons/bench.svg', NULL, 14, true, NOW(), NOW()),

  -- FABRIC 类别 (布料系)
  ('cuid_equipment_towel', 'towel', '毛巾', 'FABRIC', true, '{"towel", "cloth", "fabric"}', 0.70, 'https://cdn.snaprep.com/icons/towel.svg', NULL, 15, true, NOW(), NOW()),

  -- STICK 类别 (棍棒系)
  ('cuid_equipment_umbrella', 'umbrella', '雨伞', 'STICK', true, '{"umbrella", "parasol"}', 0.85, 'https://cdn.snaprep.com/icons/umbrella.svg', NULL, 16, true, NOW(), NOW()),
  ('cuid_equipment_mop', 'mop', '拖把', 'STICK', true, '{"mop", "cleaning tool"}', 0.75, 'https://cdn.snaprep.com/icons/mop.svg', NULL, 17, true, NOW(), NOW()),

  -- OUTDOOR 类别 (户外系)
  ('cuid_equipment_tree', 'tree', '树木', 'OUTDOOR', true, '{"tree", "trunk", "branch"}', 0.90, 'https://cdn.snaprep.com/icons/tree.svg', 'https://cdn.snaprep.com/images/tree.jpg', 18, true, NOW(), NOW()),
  ('cuid_equipment_rock', 'rock', '石头', 'OUTDOOR', true, '{"rock", "stone", "boulder"}', 0.75, 'https://cdn.snaprep.com/icons/rock.svg', NULL, 19, true, NOW(), NOW()),

  -- CREATIVE 类别 (创意系)
  ('cuid_equipment_book', 'book', '书本', 'CREATIVE', true, '{"book", "textbook", "novel"}', 0.80, 'https://cdn.snaprep.com/icons/book.svg', NULL, 20, true, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 验证插入结果
SELECT
  'Equipment 数据统计' as category,
  COUNT(*) as total_count,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_count,
  STRING_AGG(DISTINCT category::text, ', ') as categories
FROM equipment;

-- 显示新插入的器材信息
SELECT id, code, name, category, display_order, is_active
FROM equipment
ORDER BY display_order;
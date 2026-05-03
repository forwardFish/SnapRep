# 直接跳转到动作结果页使用指南

根据你的需求，现在已经配置好了两种直接跳转到动作结果页的方式：

## 🎯 使用方法

### 1️⃣ 首页器材点击 → 直接跳转动作结果页

```dart
// 在首页器材点击事件中使用
void onEquipmentTap(String equipmentCode) {
  AppRoutes.equipmentQuickSelect(context, equipmentCode: equipmentCode);
}

// 示例：椅子点击
AppRoutes.equipmentQuickSelect(context, equipmentCode: 'chair');
```

**支持的器材代码**:
- `'chair'` - 椅子 (办公室场景，拉伸意图)
- `'wall'` - 墙面 (办公室场景，拉伸意图)
- `'sofa'` - 沙发 (客厅场景，放松意图)
- `'bottle'` - 水瓶 (办公室场景，力量意图)
- `'stairs'` - 楼梯 (户外场景，有氧意图)
- `'hands_free'` - 空手 (居家场景，拉伸意图)

### 2️⃣ 挑战页面器材点击 → 直接跳转动作结果页

```dart
// 在挑战详情页面器材点击事件中使用
void onChallengeEquipmentTap(String equipmentCode) {
  AppRoutes.challengeQuickJoin(
    context,
    challengeId: 'your-challenge-id', // 当前挑战ID
    equipmentCode: equipmentCode,
  );
}

// 示例：椅子挑战
AppRoutes.challengeQuickJoin(
  context,
  challengeId: 'chair-week-2024',
  equipmentCode: 'chair',
);
```

## 🔄 跳转流程

### 首页器材点击流程：
```
首页器材九宫格 → equipmentQuickSelect() → 动作结果页
```

### 挑战器材点击流程：
```
挑战详情页 → challengeQuickJoin() → 动作结果页
```

## ⚙️ 预设配置

每个器材都有预设的配置，会自动传递给推荐系统：

```dart
// 椅子预设
{
  'equipment': ['chair'],
  'intent': 'STRETCH',      // 拉伸意图
  'scenario': 'office',     // 办公室场景
  'tags': ['silent', 'sitting'],
}

// 水瓶预设
{
  'equipment': ['bottle'],
  'intent': 'STRENGTH',     // 力量意图
  'scenario': 'office',     // 办公室场景
  'tags': ['lightweight'],
}
```

## 🎨 UI集成示例

### 首页器材网格

```dart
GridView.builder(
  itemBuilder: (context, index) {
    final equipment = equipments[index];
    return GestureDetector(
      onTap: () => AppRoutes.equipmentQuickSelect(
        context,
        equipmentCode: equipment['code']
      ),
      child: EquipmentTile(equipment: equipment),
    );
  },
);
```

### 挑战页面器材列表

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final equipment = challengeEquipments[index];
    return ListTile(
      onTap: () => AppRoutes.challengeQuickJoin(
        context,
        challengeId: widget.challengeId,
        equipmentCode: equipment['code'],
      ),
      title: Text(equipment['name']),
    );
  },
);
```

## ✅ 完成

现在你的用户可以：
1. **在首页点击任何器材** → 直接进入动作结果页
2. **在挑战页面点击器材** → 直接进入动作结果页

无需经过引导步骤，用户体验更加流畅！
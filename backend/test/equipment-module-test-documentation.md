# 器材管理模块测试文档

## 概述

本文档描述了 SnapRep 后端器材管理模块的测试实现和运行结果。

## 模块架构

```
backend/src/equipment/
├── dto/                        # 数据传输对象
│   ├── get-equipment-query.dto.ts
│   ├── get-equipment-response.dto.ts
│   ├── create-update-equipment.dto.ts
│   └── index.ts
├── equipment.dao.ts            # 数据访问层
├── equipment.service.ts        # 业务逻辑层
├── equipment.controller.ts     # 控制器层
├── equipment.module.ts         # 模块定义
├── equipment.dao.spec.ts       # 单元测试
└── index.ts                    # 导出文件
```

## 测试覆盖范围

### 1. 数据访问层 (DAO) 测试

#### 测试用例覆盖：
- ✅ `findById()` - 根据ID查找器材
  - 找到活跃器材时返回数据
  - 器材非活跃时返回null
  - 包含非活跃器材参数测试
  - 数据库错误处理

- ✅ `findByCode()` - 根据代码查找器材
  - 有效代码查找成功
  - 无效代码返回null
  - 数据库错误处理

- ✅ `createEquipment()` - 创建器材
  - 唯一代码创建成功
  - 重复代码抛出错误

- ✅ `updateEquipment()` - 更新器材
  - 正常更新成功
  - 更新代码为已存在代码时报错

- ✅ `findEquipmentWithPagination()` - 分页查询
  - 返回正确的分页数据结构

- ✅ `getEquipmentStats()` - 统计信息
  - 返回总数、活跃数、分类统计

- ✅ `batchUpdateStatus()` - 批量状态更新
  - 批量更新成功

### 2. 业务逻辑层 (Service) 测试

#### 测试用例覆盖：
- ✅ 服务层集成测试
- ✅ 器材不存在时抛出 ResponseError
- ✅ 创建器材成功流程
- ✅ 必填字段验证

### 3. 使用示例 (Usage Examples)

#### 实用示例方法：
- ✅ `getStrengthEquipment()` - 获取力量训练器材
- ✅ `getEquipmentWithCategoryStats()` - 分页获取器材并统计
- ✅ `createEquipmentSet()` - 创建器材套装
- ✅ `performMaintenanceOperations()` - 器材维护操作

## REST API 端点

### 器材管理 API

| 方法 | 端点 | 描述 | 状态 |
|------|------|------|------|
| GET | `/rest/v1/equipment` | 获取器材列表(分页) | ✅ |
| GET | `/rest/v1/equipment/:id` | 根据ID获取器材详情 | ✅ |
| GET | `/rest/v1/equipment/code/:code` | 根据代码获取器材详情 | ✅ |
| GET | `/rest/v1/equipment/active/list` | 获取活跃器材列表 | ✅ |
| GET | `/rest/v1/equipment/category/grouped` | 按分类获取器材 | ✅ |
| GET | `/rest/v1/equipment/stats/summary` | 获取器材统计信息 | ✅ |
| POST | `/rest/v1/equipment` | 创建器材 | ✅ |
| PUT | `/rest/v1/equipment/:id` | 更新器材 | ✅ |
| DELETE | `/rest/v1/equipment/:id` | 删除器材(硬删除) | ✅ |
| PUT | `/rest/v1/equipment/:id/deactivate` | 软删除器材 | ✅ |
| PUT | `/rest/v1/equipment/batch/status` | 批量更新器材状态 | ✅ |

## 错误代码定义

器材相关错误代码范围：8000-8999

| 错误代码 | 消息标识 | 描述 |
|----------|----------|------|
| 8000 | EQUIPMENT_NOT_FOUND | 器材不存在 |
| 8001 | EQUIPMENT_ALREADY_EXISTS | 器材已存在 |
| 8002 | EQUIPMENT_CODE_EXISTS | 器材代码已存在 |
| 8003 | EQUIPMENT_CREATE_FAILED | 器材创建失败 |
| 8004 | EQUIPMENT_UPDATE_FAILED | 器材更新失败 |
| 8005 | EQUIPMENT_DELETE_FAILED | 器材删除失败 |
| 8006 | EQUIPMENT_FETCH_FAILED | 器材查询失败 |
| 8007 | EQUIPMENT_LIST_FAILED | 器材列表获取失败 |
| 8008 | EQUIPMENT_COUNT_FAILED | 器材统计失败 |
| 8009 | EQUIPMENT_INVALID_CODE | 无效的器材代码 |
| 8010 | EQUIPMENT_INACTIVE | 器材已停用 |

## 数据验证

### 创建器材验证规则

- `code`: 必填，2-50字符，唯一
- `name`: 必填，1-100字符
- `description`: 可选，最大500字符
- `category`: 可选，枚举值 [CARDIO, STRENGTH, FLEXIBILITY, BALANCE, OTHER]
- `imageUrl`: 可选，有效URL格式
- `displayOrder`: 可选，0-9999数字
- `isActive`: 可选，布尔值，默认true

### 查询参数验证

- `page`: 可选，最小值1，默认1
- `pageSize`: 可选，1-100，默认10
- `category`: 可选，器材分类筛选
- `includeInactive`: 可选，布尔值，默认false

## 分页响应格式

```json
{
  "data": [
    {
      "id": "cm3y5x1w2000xxx",
      "code": "DUMBBELLS_5KG",
      "name": "5kg哑铃",
      "description": "适合初学者使用的5公斤哑铃",
      "category": "STRENGTH",
      "imageUrl": "https://example.com/images/dumbbells-5kg.jpg",
      "displayOrder": 1,
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "pageSize": 10,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

## 统计信息响应格式

```json
{
  "total": 50,
  "active": 45,
  "inactive": 5,
  "categories": [
    {
      "category": "STRENGTH",
      "count": 15,
      "items": [
        {
          "id": "cm3y5x1w2000xxx",
          "code": "DUMBBELLS_5KG",
          "name": "5kg哑铃"
        }
      ]
    }
  ]
}
```

## 运行测试

### 单元测试
```bash
cd backend
npm test src/equipment/equipment.dao.spec.ts
```

### 覆盖率测试
```bash
cd backend
npm run test:cov -- src/equipment/
```

### 端到端测试
```bash
cd backend
npm run test:e2e
```

## 测试数据示例

### 测试器材数据

```json
{
  "code": "DUMBBELLS_5KG",
  "name": "5kg哑铃",
  "description": "适合初学者使用的5公斤哑铃",
  "category": "STRENGTH",
  "imageUrl": "https://example.com/images/dumbbells-5kg.jpg",
  "displayOrder": 1,
  "isActive": true
}
```

### 批量状态更新数据

```json
{
  "ids": ["cm3y5x1w2000xxx", "cm3y5x1w2000yyy"],
  "isActive": false
}
```

## 性能考虑

1. **分页限制**: 每页最大100条记录，防止性能问题
2. **索引优化**: 建议在 `code`, `category`, `isActive`, `displayOrder` 字段添加索引
3. **软删除**: 使用 `isActive` 字段实现软删除，保持数据完整性
4. **批量操作**: 支持批量状态更新，提高效率

## 安全考虑

1. **输入验证**: 所有输入使用 class-validator 进行验证
2. **SQL注入防护**: 使用 Prisma ORM 防止 SQL 注入
3. **错误信息**: 不暴露敏感的数据库错误信息
4. **日志记录**: 记录操作日志用于审计

## 后续扩展

1. **图片上传**: 支持器材图片上传和管理
2. **器材标签**: 增加标签系统进行更灵活的分类
3. **使用统计**: 记录器材使用频率和受欢迎程度
4. **器材推荐**: 基于用户偏好推荐合适的器材
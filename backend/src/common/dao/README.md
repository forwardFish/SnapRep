# Prisma DAO Layer Implementation

这个项目实现了一个基于Prisma的DAO（数据访问对象）层，提供了统一的数据库操作接口和错误处理机制。

## 架构概述

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Controller    │────│    Service      │────│      DAO        │
│  (HTTP Layer)   │    │ (Business Logic)│    │ (Data Access)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │  PrismaService  │
                                               │   (Database)    │
                                               └─────────────────┘
```

## 核心组件

### 1. PrismaBaseDao (基础DAO抽象类)

位置: `src/common/dao/prisma-base.dao.ts`

提供通用的CRUD操作：
- `create()` - 创建实体
- `findUnique()` - 根据唯一条件查询
- `findFirst()` - 查询第一个匹配的记录
- `findMany()` - 查询多条记录
- `findByPage()` - 分页查询
- `update()` - 更新记录
- `updateMany()` - 批量更新
- `delete()` - 删除记录
- `deleteMany()` - 批量删除
- `count()` - 统计数量
- `exists()` - 检查是否存在
- `upsert()` - 更新或插入
- `createMany()` - 批量创建
- `transaction()` - 事务操作

### 2. ResponseError (统一错误处理)

位置: `src/exception/response-error.ts`

提供统一的错误格式：
- 错误代码 (code)
- 国际化键 (i18nKey)
- 上下文信息 (context)
- 时间戳 (timestamp)
- 原始错误 (originalCause)

### 3. ErrorCodes (错误代码定义)

位置: `src/exception/error-codes.ts`

定义了系统中的所有错误代码，包括：
- 通用错误 (1000-1999)
- 用户相关错误 (2000-2999)
- 认证相关错误 (3000-3999)
- 场景相关错误 (7000-7999)

## 使用示例

### 1. 创建场景DAO

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';

@Injectable()
export class ScenariosDao extends PrismaBaseDao<any> {
  private readonly logger = new Logger(ScenariosDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
  }

  protected getDelegate() {
    return this.prisma.scenario;
  }

  // 自定义业务方法
  async findByCode(code: string): Promise<any | null> {
    try {
      return await this.findFirst(
        { code, isActive: true },
        { exerciseScenarios: true }
      );
    } catch (error) {
      this.logger.error(`查找场景失败: code=${code}`, error);
      throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error);
    }
  }
}
```

### 2. 在Service中使用DAO

```typescript
@Injectable()
export class ScenariosService {
  constructor(private scenariosDao: ScenariosDao) {}

  async findAll(queryDto: GetScenariosQueryDto) {
    try {
      const result = await this.scenariosDao.findScenariosWithPagination(
        queryDto.page,
        queryDto.pageSize,
        false, // 不包含非活跃场景
        false  // 不包含关联数据
      );

      return {
        data: result.data.map(scenario => ({
          id: scenario.id,
          code: scenario.code,
          name: scenario.name,
          // ... 其他字段
        })),
        pagination: result.pagination,
      };
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SCENARIO.LIST_FAILED, error);
    }
  }
}
```

### 3. 在Controller中处理错误

```typescript
@Controller('rest/v1/scenarios')
export class ScenariosController {
  constructor(private readonly scenariosService: ScenariosService) {}

  @Get()
  async findAll(@Query() queryDto: GetScenariosQueryDto) {
    try {
      return await this.scenariosService.findAll(queryDto);
    } catch (error) {
      this.handleError(error, 'findAll', { queryDto });
    }
  }

  private handleError(error: any, method: string, context?: any): never {
    if (error instanceof ResponseError) {
      switch (error.code) {
        case ErrorCodes.SCENARIO.NOT_FOUND.code:
          throw new NotFoundException(error.getUserMessage());
        case ErrorCodes.SCENARIO.INVALID_CODE.code:
          throw new BadRequestException(error.getUserMessage());
        default:
          throw new InternalServerErrorException('服务器内部错误');
      }
    }
    throw new InternalServerErrorException('服务器内部错误');
  }
}
```

## 错误处理模式

### 1. DAO层错误处理

```typescript
async findById(id: string): Promise<any | null> {
  try {
    const result = await this.findUnique({ id });
    if (!result) {
      return null;
    }
    return result;
  } catch (error) {
    this.logger.error(`查找失败: id=${id}`, error);
    throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { id });
  }
}
```

### 2. Service层错误处理

```typescript
async findOne(id: string) {
  try {
    const scenario = await this.scenariosDao.findById(id);
    if (!scenario) {
      throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND, undefined, { id });
    }
    return scenario;
  } catch (error) {
    if (error instanceof ResponseError) {
      throw error; // 传递DAO层的错误
    }
    throw new ResponseError(ErrorCodes.SCENARIO.FETCH_FAILED, error, { id });
  }
}
```

### 3. Controller层错误映射

```typescript
private handleError(error: any, method: string, context?: any): never {
  if (error instanceof ResponseError) {
    switch (error.code) {
      case ErrorCodes.SCENARIO.NOT_FOUND.code:
        throw new NotFoundException(error.getUserMessage());
      case ErrorCodes.COMMON.VALIDATION_ERROR.code:
        throw new BadRequestException(error.getUserMessage());
      default:
        throw new InternalServerErrorException('服务器内部错误');
    }
  }
  throw new InternalServerErrorException('服务器内部错误');
}
```

## 分页查询示例

```typescript
// 基本分页查询
const result = await scenariosDao.findByPage(1, 10, { isActive: true });

// 带关联数据的分页查询
const result = await scenariosDao.findByPage(
  1,
  10,
  { isActive: true },
  { exerciseScenarios: { include: { exercise: true } } },
  undefined,
  [{ createdAt: 'desc' }]
);

// 返回结果格式
{
  data: [/* 场景数据 */],
  pagination: {
    total: 50,
    page: 1,
    pageSize: 10,
    totalPages: 5,
    hasNextPage: true,
    hasPreviousPage: false,
  },
}
```

## 事务操作示例

```typescript
async transferScenarioOwnership(fromUserId: string, toUserId: string, scenarioId: string) {
  return await this.scenariosDao.transaction(async (prisma) => {
    // 验证场景存在
    const scenario = await prisma.scenario.findUnique({ where: { id: scenarioId } });
    if (!scenario) {
      throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND);
    }

    // 更新场景所有者
    const updatedScenario = await prisma.scenario.update({
      where: { id: scenarioId },
      data: { ownerId: toUserId },
    });

    // 记录转移日志
    await prisma.ownershipLog.create({
      data: {
        scenarioId,
        fromUserId,
        toUserId,
        transferredAt: new Date(),
      },
    });

    return updatedScenario;
  });
}
```

## 测试示例

参考 `src/scenarios/scenarios.dao.spec.ts` 文件，包含：
- DAO层单元测试
- Service层集成测试
- 错误处理测试
- 完整的用法示例

## 扩展新的DAO

1. 创建新的DAO类继承 `PrismaBaseDao`
2. 实现 `getDelegate()` 方法
3. 添加特定的业务方法
4. 在相应的错误代码文件中添加错误定义
5. 在Module中注册DAO和Service

```typescript
@Injectable()
export class UsersDao extends PrismaBaseDao<any> {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  protected getDelegate() {
    return this.prisma.user;
  }

  async findByEmail(email: string): Promise<any | null> {
    return await this.findUnique({ email });
  }
}
```

## 最佳实践

1. **错误处理**: 始终使用 ResponseError 进行错误封装
2. **日志记录**: 在DAO层记录操作日志
3. **参数验证**: 在Service层验证业务逻辑
4. **分页限制**: 限制每页最大记录数（建议100）
5. **事务管理**: 对于复杂操作使用事务确保数据一致性
6. **缓存策略**: 对频繁查询的数据考虑添加缓存
7. **性能优化**: 只查询需要的字段，避免N+1查询问题

## 依赖项

- `@nestjs/common`: NestJS核心模块
- `nestjs-prisma`: Prisma集成模块
- `@prisma/client`: Prisma客户端 (需要正确生成)

确保运行 `npm run prisma:generate` 来生成Prisma客户端。
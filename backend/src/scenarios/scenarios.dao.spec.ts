import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from 'nestjs-prisma';
import { ScenariosDao } from './scenarios.dao';
import { ScenariosService } from './scenarios.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

// Mock Prisma Service
const mockPrismaService = {
  scenario: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    updateMany: jest.fn(),
  },
};

describe('ScenariosDao', () => {
  let dao: ScenariosDao;
  let service: ScenariosService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ScenariosDao,
        ScenariosService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    dao = module.get<ScenariosDao>(ScenariosDao);
    service = module.get<ScenariosService>(ScenariosService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findById', () => {
    it('should return scenario when found and active', async () => {
      const mockScenario = {
        id: 'test-id',
        code: 'office',
        name: 'Office',
        isActive: true,
        noiseTolerance: 'SILENT',
        spaceRequirement: 'SMALL',
        exerciseScenarios: [],
        workoutSessions: [],
      };

      mockPrismaService.scenario.findUnique.mockResolvedValue(mockScenario);

      const result = await dao.findById('test-id');

      expect(result).toEqual(mockScenario);
      expect(mockPrismaService.scenario.findUnique).toHaveBeenCalledWith({
        where: { id: 'test-id', isActive: true },
      });
    });

    it('should return null when scenario is inactive', async () => {
      const mockScenario = {
        id: 'test-id',
        code: 'office',
        name: 'Office',
        isActive: false,
      };

      mockPrismaService.scenario.findUnique.mockResolvedValue(null);

      const result = await dao.findById('test-id');

      expect(result).toBeNull();
    });

    it('should throw ResponseError when database error occurs', async () => {
      const dbError = new Error('Database connection failed');
      mockPrismaService.scenario.findUnique.mockRejectedValue(dbError);

      await expect(dao.findById('test-id')).rejects.toThrow(ResponseError);
      await expect(dao.findById('test-id')).rejects.toMatchObject({
        code: ErrorCodes.SCENARIO.FETCH_FAILED.code,
      });
    });
  });

  describe('findByCode', () => {
    it('should return scenario when found with valid code', async () => {
      const mockScenario = {
        id: 'test-id',
        code: 'office',
        name: 'Office',
        isActive: true,
      };

      mockPrismaService.scenario.findUnique.mockResolvedValue(mockScenario);

      const result = await dao.findByCode('office');

      expect(result).toEqual(mockScenario);
      expect(mockPrismaService.scenario.findUnique).toHaveBeenCalledWith({
        where: {
          code: 'office',
          isActive: true,
        },
      });
    });
  });

  describe('getActiveCount', () => {
    it('should return count of active scenarios', async () => {
      mockPrismaService.scenario.count.mockResolvedValue(5);

      const result = await dao.getActiveCount();

      expect(result).toBe(5);
      expect(mockPrismaService.scenario.count).toHaveBeenCalledWith({
        where: { isActive: true },
      });
    });
  });

  describe('createScenario', () => {
    it('should create scenario when code is unique', async () => {
      const createData = {
        code: 'new-scenario',
        name: 'New Scenario',
        isActive: true,
      };

      const mockCreatedScenario = {
        id: 'new-id',
        ...createData,
      };

      // Mock code existence check to return false
      mockPrismaService.scenario.count.mockResolvedValue(0);
      mockPrismaService.scenario.create.mockResolvedValue(mockCreatedScenario);

      const result = await dao.createScenario(createData);

      expect(result).toEqual(mockCreatedScenario);
      expect(mockPrismaService.scenario.create).toHaveBeenCalledWith({
        data: {
          ...createData,
          isActive: true,
        },
      });
    });

    it('should throw ResponseError when code already exists', async () => {
      const createData = {
        code: 'existing-scenario',
        name: 'Existing Scenario',
        isActive: true,
      };

      // Mock code existence check to return true
      mockPrismaService.scenario.count.mockResolvedValue(1);

      await expect(dao.createScenario(createData)).rejects.toThrow(ResponseError);
      await expect(dao.createScenario(createData)).rejects.toMatchObject({
        code: ErrorCodes.SCENARIO.CODE_EXISTS.code,
      });
    });
  });

  describe('ScenariosService integration', () => {
    it('should handle service-level operations correctly', async () => {
      const mockScenarios = [
        {
          id: 'id1',
          code: 'office',
          name: 'Office',
          isActive: true,
        },
        {
          id: 'id2',
          code: 'home',
          name: 'Home',
          isActive: true,
        },
      ];

      mockPrismaService.scenario.findMany.mockResolvedValue(mockScenarios);
      mockPrismaService.scenario.count.mockResolvedValue(2);

      const result = await service.findAll({ page: 1, pageSize: 10 });

      expect(result.data).toHaveLength(2);
      expect(result.pagination.total).toBe(2);
      expect(result.pagination.page).toBe(1);
      expect(result.pagination.pageSize).toBe(10);
    });

    it('should throw ResponseError when scenario not found', async () => {
      mockPrismaService.scenario.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent-id')).rejects.toThrow(ResponseError);
      await expect(service.findOne('non-existent-id')).rejects.toMatchObject({
        code: ErrorCodes.SCENARIO.NOT_FOUND.code,
      });
    });
  });
});

/**
 * 演示用法示例
 */
export class ScenariosUsageExample {
  constructor(private scenariosDao: ScenariosDao) {}

  /**
   * 示例：获取办公室场景的所有相关运动
   */
  async getOfficeExercises() {
    try {
      // 1. 根据代码查找场景
      const officeScenario = await this.scenariosDao.findByCode('office');

      if (!officeScenario) {
        throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND, undefined, {
          scenarioCode: 'office',
        });
      }

      // 2. 获取相关运动
      const exercises = await this.scenariosDao.getRelatedExercises(officeScenario.id);

      return {
        scenario: officeScenario,
        exercises: exercises,
        exerciseCount: exercises.length,
      };
    } catch (error) {
      console.error('Failed to get office exercises:', error);
      throw error;
    }
  }

  /**
   * 示例：分页获取场景并筛选
   */
  async getScenariosWithPagination(page: number = 1, pageSize: number = 10) {
    try {
      // 1. 分页获取所有活跃场景
      const result = await this.scenariosDao.findScenariosWithPagination(
        page,
        pageSize,
        false, // 不包含非活跃场景
        true   // 包含关联数据
      );

      // 2. 按噪音等级分类
      const scenariosByNoise = result.data.reduce((acc: any, scenario: any) => {
        const noiseLevel = scenario.noiseTolerance || 'UNKNOWN';
        if (!acc[noiseLevel]) {
          acc[noiseLevel] = [];
        }
        acc[noiseLevel].push(scenario);
        return acc;
      }, {});

      return {
        scenarios: result.data,
        pagination: result.pagination,
        categorized: scenariosByNoise,
        summary: {
          total: result.pagination.total,
          byNoiseLevel: Object.keys(scenariosByNoise).map(level => ({
            level,
            count: scenariosByNoise[level].length,
          })),
        },
      };
    } catch (error) {
      console.error('Failed to get scenarios with pagination:', error);
      throw error;
    }
  }

  /**
   * 示例：创建新场景
   */
  async createNewScenario(scenarioData: any) {
    try {
      // 1. 验证必需字段
      if (!scenarioData.code || !scenarioData.name) {
        throw new ResponseError(ErrorCodes.COMMON.VALIDATION_ERROR, undefined, {
          missingFields: ['code', 'name'],
        });
      }

      // 2. 创建场景
      const newScenario = await this.scenariosDao.createScenario({
        ...scenarioData,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // 3. 获取创建后的完整数据
      const fullScenario = await this.scenariosDao.findById(newScenario.id, false);

      return {
        scenario: fullScenario,
        message: `Scenario '${newScenario.name}' created successfully`,
      };
    } catch (error) {
      console.error('Failed to create new scenario:', error);
      throw error;
    }
  }

  /**
   * 示例：批量操作场景状态
   */
  async batchUpdateScenarioStatus(scenarioIds: string[], isActive: boolean) {
    try {
      // 1. 验证场景存在
      const existingScenarios = await Promise.all(
        scenarioIds.map(id => this.scenariosDao.findById(id, true))
      );

      const notFoundIds = scenarioIds.filter((id, index) => !existingScenarios[index]);
      if (notFoundIds.length > 0) {
        throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND, undefined, {
          notFoundIds,
        });
      }

      // 2. 批量更新状态
      const updateResult = await this.scenariosDao.batchUpdateStatus(scenarioIds, isActive);

      // 3. 获取更新后的场景列表
      const updatedScenarios = await Promise.all(
        scenarioIds.map(id => this.scenariosDao.findById(id, true))
      );

      return {
        updated: updateResult.count,
        scenarios: updatedScenarios,
        message: `Successfully ${isActive ? 'activated' : 'deactivated'} ${updateResult.count} scenarios`,
      };
    } catch (error) {
      console.error('Failed to batch update scenario status:', error);
      throw error;
    }
  }
}
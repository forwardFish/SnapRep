import { forwardRef, Inject, Injectable, Logger } from '@nestjs/common';
import { GetScenariosQueryDto } from './dto/get-scenarios-query.dto';
import { ScenariosDao } from './scenarios.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

@Injectable()
export class ScenariosService {
  private readonly logger = new Logger(ScenariosService.name);

    @Inject(forwardRef(() => ScenariosDao))
    public scenariosDao: ScenariosDao;

  // constructor(private scenariosDao: ScenariosDao) {}
  constructor() {
    this.logger.log('ScenariosService initialized (temporary mode without Prisma)');
  }

  /**
   * 获取场景列表 (支持分页)
   * 用途: 首页场景区显示「办公室」「客厅/沙发」等场景选项
   *
   * TEMPORARY IMPLEMENTATION: Returns mock data until Prisma is working
   */
  async findAll(queryDto: GetScenariosQueryDto) {
    try {
      const { page = 1, pageSize = 10 } = queryDto;

      this.logger.log(`Fetching scenarios with pagination: page=${page}, pageSize=${pageSize}`);

      // Mock data until Prisma is working
      const mockScenarios = [
        {
          id: 'scenario-001',
          code: 'office',
          name: 'Office',
          iconUrl: '/icons/office.svg',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: 'scenario-002',
          code: 'home',
          name: 'Home',
          iconUrl: '/icons/home.svg',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: 'scenario-003',
          code: 'gym',
          name: 'Gym',
          iconUrl: '/icons/gym.svg',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: 'scenario-004',
          code: 'park',
          name: 'Park',
          iconUrl: '/icons/park.svg',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];

      const total = mockScenarios.length;
      const skip = (page - 1) * pageSize;
      const take = pageSize;

      const data = mockScenarios.slice(skip, skip + take);
      const totalPages = Math.ceil(total / pageSize);
      const hasNextPage = page < totalPages;
      const hasPreviousPage = page > 1;

      return {
        data,
        pagination: {
          total,
          page,
          pageSize,
          totalPages,
          hasNextPage,
          hasPreviousPage,
        },
      };
    } catch (error) {
      this.logger.error(`Failed to fetch scenarios: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据ID获取单个场景
   * TEMPORARY IMPLEMENTATION: Returns mock data until Prisma is working
   */
  async findOne(id: string) {
    try {
      this.logger.log(`Fetching scenario by ID: ${id}`);

      // Mock data until Prisma is working
      const mockScenario = {
        id,
        code: 'office',
        name: 'Office',
        iconUrl: '/icons/office.svg',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      return mockScenario;
    } catch (error) {
      this.logger.error(`Failed to fetch scenario by ID ${id}: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据代码获取场景
   * TEMPORARY IMPLEMENTATION: Returns mock data until Prisma is working
   */
  async findByCode(code: string) {
    try {
      this.logger.log(`Fetching scenario by code: ${code}`);

      // Mock data until Prisma is working
      const mockScenario = {
        id: 'scenario-001',
        code,
        name: code.charAt(0).toUpperCase() + code.slice(1),
        iconUrl: `/icons/${code}.svg`,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      return mockScenario;
    } catch (error) {
      this.logger.error(`Failed to fetch scenario by code ${code}: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取活跃场景数量统计
   * TEMPORARY IMPLEMENTATION: Returns mock data until Prisma is working
   */
  async getActiveCount(): Promise<number> {
    try {
      this.logger.log('Fetching active scenarios count');

      // Mock data until Prisma is working
      return 4;
    } catch (error) {
      this.logger.error(`Failed to get active scenarios count: ${error.message}`);
      throw error;
    }
  }
}
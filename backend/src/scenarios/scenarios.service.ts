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


  constructor() {
    this.logger.log('ScenariosService initialized');
  }

  /**
   * 获取场景列表 (支持分页)
   * 用途: 首页场景区显示「办公室」「客厅/沙发」等场景选项
   */
  async findAll(queryDto: GetScenariosQueryDto) {
    try {
      const { page = 1, pageSize = 10 } = queryDto;

      this.logger.log(`Fetching scenarios with pagination: page=${page}, pageSize=${pageSize}`);

      return await this.scenariosDao.findScenariosWithPagination(page, pageSize);
    } catch (error) {
      this.logger.error(`Failed to fetch scenarios: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据ID获取单个场景
   */
  async findOne(id: string) {
    try {
      this.logger.log(`Fetching scenario by ID: ${id}`);

      const scenario = await this.scenariosDao.findById(id);
      if (!scenario) {
        throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND);
      }

      return scenario;
    } catch (error) {
      this.logger.error(`Failed to fetch scenario by ID ${id}: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据代码获取场景
   */
  async findByCode(code: string) {
    try {
      this.logger.log(`Fetching scenario by code: ${code}`);

      const scenario = await this.scenariosDao.findByCode(code);
      if (!scenario) {
        throw new ResponseError(ErrorCodes.SCENARIO.NOT_FOUND);
      }

      return scenario;
    } catch (error) {
      this.logger.error(`Failed to fetch scenario by code ${code}: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取活跃场景数量统计
   */
  async getActiveCount(): Promise<number> {
    try {
      this.logger.log('Fetching active scenarios count');

      return await this.scenariosDao.getActiveCount();
    } catch (error) {
      this.logger.error(`Failed to get active scenarios count: ${error.message}`);
      throw error;
    }
  }
}
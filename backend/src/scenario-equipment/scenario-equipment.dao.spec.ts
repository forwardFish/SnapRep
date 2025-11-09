// import { Test, TestingModule } from '@nestjs/testing';
// import { PrismaService } from 'nestjs-prisma';
// import { EquipmentDao } from './scenario-equipment.dao';
// import { EquipmentService } from './scenario-equipment.service';
// import { ResponseError } from '../exception/response-error';
// import { ErrorCodes } from '../exception/error-codes';
// import { EquipmentCategory } from './dto/create-update-equipment.dto';

// // Mock Prisma Service
// const mockPrismaService = {
//   equipment: {
//     findUnique: jest.fn(),
//     findFirst: jest.fn(),
//     findMany: jest.fn(),
//     count: jest.fn(),
//     create: jest.fn(),
//     update: jest.fn(),
//     delete: jest.fn(),
//     updateMany: jest.fn(),
//   },
//   $transaction: jest.fn(),
// };

// describe('EquipmentDao', () => {
//   let dao: EquipmentDao;
//   let service: EquipmentService;
//   let prisma: PrismaService;

//   beforeEach(async () => {
//     const module: TestingModule = await Test.createTestingModule({
//       providers: [
//         EquipmentDao,
//         EquipmentService,
//         {
//           provide: PrismaService,
//           useValue: mockPrismaService,
//         },
//       ],
//     }).compile();

//     dao = module.get<EquipmentDao>(EquipmentDao);
//     service = module.get<EquipmentService>(EquipmentService);
//     prisma = module.get<PrismaService>(PrismaService);
//   });

//   afterEach(() => {
//     jest.clearAllMocks();
//   });

//   describe('EquipmentDao - findById', () => {
//     it('should return equipment when found and active', async () => {
//       const mockEquipment = {
//         id: 'test-equipment-id',
//         code: 'DUMBBELLS_5KG',
//         name: '5kg哑铃',
//         description: '适合初学者使用的5公斤哑铃',
//         category: EquipmentCategory.STRENGTH,
//         imageUrl: 'https://example.com/images/dumbbells-5kg.jpg',
//         displayOrder: 1,
//         isActive: true,
//         createdAt: new Date('2024-01-01T00:00:00.000Z'),
//         updatedAt: new Date('2024-01-01T00:00:00.000Z'),
//       };

//       mockPrismaService.equipment.findUnique.mockResolvedValue(mockEquipment);

//       const result = await dao.findById('test-equipment-id');

//       expect(result).toEqual(mockEquipment);
//       expect(mockPrismaService.equipment.findUnique).toHaveBeenCalledWith({
//         where: { id: 'test-equipment-id', isActive: true },
//       });
//     });

//     it('should return null when equipment is inactive', async () => {
//       // When includeInactive=false (default), the DAO adds isActive: true to where clause
//       // So an inactive equipment would not be found by the query
//       mockPrismaService.equipment.findUnique.mockResolvedValue(null);

//       const result = await dao.findById('test-equipment-id');

//       expect(result).toBeNull();
//       expect(mockPrismaService.equipment.findUnique).toHaveBeenCalledWith({
//         where: { id: 'test-equipment-id', isActive: true },
//       });
//     });

//     it('should return inactive equipment when includeInactive is true', async () => {
//       const mockEquipment = {
//         id: 'test-equipment-id',
//         code: 'DUMBBELLS_5KG',
//         name: '5kg哑铃',
//         isActive: false,
//       };

//       mockPrismaService.equipment.findUnique.mockResolvedValue(mockEquipment);

//       const result = await dao.findById('test-equipment-id', true);

//       expect(result).toEqual(mockEquipment);
//       expect(mockPrismaService.equipment.findUnique).toHaveBeenCalledWith({
//         where: { id: 'test-equipment-id' },
//       });
//     });

//     it('should throw ResponseError when database error occurs', async () => {
//       const dbError = new Error('Database connection failed');
//       mockPrismaService.equipment.findUnique.mockRejectedValue(dbError);

//       await expect(dao.findById('test-equipment-id')).rejects.toThrow(ResponseError);
//       await expect(dao.findById('test-equipment-id')).rejects.toMatchObject({
//         code: ErrorCodes.EQUIPMENT.FETCH_FAILED.code,
//       });
//     });
//   });

//   describe('EquipmentDao - findByCode', () => {
//     it('should return equipment when found with valid code', async () => {
//       const mockEquipment = {
//         id: 'test-equipment-id',
//         code: 'DUMBBELLS_5KG',
//         name: '5kg哑铃',
//         isActive: true,
//       };

//       mockPrismaService.equipment.findUnique.mockResolvedValue(mockEquipment);

//       const result = await dao.findByCode('DUMBBELLS_5KG');

//       expect(result).toEqual(mockEquipment);
//       expect(mockPrismaService.equipment.findUnique).toHaveBeenCalledWith({
//         where: {
//           code: 'DUMBBELLS_5KG',
//           isActive: true,
//         },
//       });
//     });

//     it('should return null when equipment not found', async () => {
//       mockPrismaService.equipment.findUnique.mockResolvedValue(null);

//       const result = await dao.findByCode('NON_EXISTENT_CODE');

//       expect(result).toBeNull();
//     });

//     it('should throw ResponseError when database error occurs', async () => {
//       const dbError = new Error('Database error');
//       mockPrismaService.equipment.findUnique.mockRejectedValue(dbError);

//       await expect(dao.findByCode('DUMBBELLS_5KG')).rejects.toThrow(ResponseError);
//       await expect(dao.findByCode('DUMBBELLS_5KG')).rejects.toMatchObject({
//         code: ErrorCodes.EQUIPMENT.FETCH_FAILED.code,
//       });
//     });
//   });

//   describe('EquipmentDao - createEquipment', () => {
//     it('should create equipment when code is unique', async () => {
//       const createData = {
//         code: 'NEW_EQUIPMENT',
//         name: 'New Equipment',
//         description: 'A new piece of equipment',
//         category: EquipmentCategory.STRENGTH,
//         isActive: true,
//       };

//       const mockCreatedEquipment = {
//         id: 'new-equipment-id',
//         ...createData,
//         createdAt: new Date(),
//         updatedAt: new Date(),
//       };

//       // Mock code existence check to return false (code doesn't exist)
//       mockPrismaService.equipment.count.mockResolvedValue(0);
//       mockPrismaService.equipment.create.mockResolvedValue(mockCreatedEquipment);

//       const result = await dao.createEquipment(createData);

//       expect(result).toEqual(mockCreatedEquipment);
//       expect(mockPrismaService.equipment.create).toHaveBeenCalledWith({
//         data: {
//           ...createData,
//           isActive: true,
//         },
//       });
//     });

//     it('should throw ResponseError when code already exists', async () => {
//       const createData = {
//         code: 'EXISTING_CODE',
//         name: 'Existing Equipment',
//         isActive: true,
//       };

//       // Mock code existence check to return true (code exists)
//       mockPrismaService.equipment.count.mockResolvedValue(1);

//       await expect(dao.createEquipment(createData)).rejects.toThrow(ResponseError);
//       await expect(dao.createEquipment(createData)).rejects.toMatchObject({
//         code: ErrorCodes.EQUIPMENT.CODE_EXISTS.code,
//       });
//     });
//   });

//   describe('EquipmentDao - updateEquipment', () => {
//     it('should update equipment successfully', async () => {
//       const updateData = {
//         name: 'Updated Equipment Name',
//         description: 'Updated description',
//       };

//       const mockUpdatedEquipment = {
//         id: 'test-equipment-id',
//         code: 'DUMBBELLS_5KG',
//         ...updateData,
//         updatedAt: new Date(),
//       };

//       mockPrismaService.equipment.update.mockResolvedValue(mockUpdatedEquipment);

//       const result = await dao.updateEquipment('test-equipment-id', updateData);

//       expect(result).toEqual(mockUpdatedEquipment);
//       expect(mockPrismaService.equipment.update).toHaveBeenCalledWith({
//         where: { id: 'test-equipment-id' },
//         data: {
//           ...updateData,
//         },
//       });
//     });

//     it('should throw ResponseError when updating code to existing one', async () => {
//       const updateData = {
//         code: 'EXISTING_CODE',
//         name: 'Updated Name',
//       };

//       // Mock finding existing equipment with same code but different ID
//       mockPrismaService.equipment.findFirst.mockResolvedValue({
//         id: 'other-equipment-id',
//         code: 'EXISTING_CODE',
//       });

//       await expect(dao.updateEquipment('test-equipment-id', updateData)).rejects.toThrow(ResponseError);
//       await expect(dao.updateEquipment('test-equipment-id', updateData)).rejects.toMatchObject({
//         code: ErrorCodes.EQUIPMENT.CODE_EXISTS.code,
//       });
//     });
//   });

//   describe('EquipmentDao - findEquipmentWithPagination', () => {
//     it('should return paginated equipment list', async () => {
//       const mockEquipment = [
//         {
//           id: 'equipment-1',
//           code: 'DUMBBELLS_5KG',
//           name: '5kg哑铃',
//           category: EquipmentCategory.STRENGTH,
//           isActive: true,
//         },
//         {
//           id: 'equipment-2',
//           code: 'TREADMILL',
//           name: '跑步机',
//           category: 'CARDIO',
//           isActive: true,
//         },
//       ];

//       mockPrismaService.equipment.findMany.mockResolvedValue(mockEquipment);
//       mockPrismaService.equipment.count.mockResolvedValue(2);

//       const result = await dao.findEquipmentWithPagination(1, 10, 'STRENGTH');

//       expect(result.data).toEqual(mockEquipment);
//       expect(result.pagination).toEqual({
//         total: 2,
//         page: 1,
//         pageSize: 10,
//         totalPages: 1,
//         hasNextPage: false,
//         hasPreviousPage: false,
//       });
//     });
//   });

//   describe('EquipmentDao - getEquipmentStats', () => {
//     it('should return equipment statistics', async () => {
//       const mockEquipmentByCategory = {
//         STRENGTH: [
//           { id: 'eq1', code: 'DUMBBELLS', name: '哑铃' },
//           { id: 'eq2', code: 'BARBELL', name: '杠铃' },
//         ],
//         CARDIO: [
//           { id: 'eq3', code: 'TREADMILL', name: '跑步机' },
//         ],
//       };

//       // Mock the methods called by getEquipmentStats
//       mockPrismaService.equipment.count
//         .mockResolvedValueOnce(10) // total count
//         .mockResolvedValueOnce(8); // active count

//       // Mock getEquipmentByCategory result
//       dao.getEquipmentByCategory = jest.fn().mockResolvedValue(mockEquipmentByCategory);

//       const result = await dao.getEquipmentStats();

//       expect(result).toEqual({
//         total: 10,
//         active: 8,
//         inactive: 2,
//         categories: [
//           {
//             category: EquipmentCategory.STRENGTH,
//             count: 2,
//             items: [
//               { id: 'eq1', code: 'DUMBBELLS', name: '哑铃' },
//               { id: 'eq2', code: 'BARBELL', name: '杠铃' },
//             ],
//           },
//           {
//             category: 'CARDIO',
//             count: 1,
//             items: [
//               { id: 'eq3', code: 'TREADMILL', name: '跑步机' },
//             ],
//           },
//         ],
//       });
//     });
//   });

//   describe('EquipmentDao - batchUpdateStatus', () => {
//     it('should batch update equipment status successfully', async () => {
//       const equipmentIds = ['eq1', 'eq2', 'eq3'];
//       const isActive = false;

//       mockPrismaService.equipment.updateMany.mockResolvedValue({ count: 3 });

//       const result = await dao.batchUpdateStatus(equipmentIds, isActive);

//       expect(result).toEqual({ count: 3 });
//       expect(mockPrismaService.equipment.updateMany).toHaveBeenCalledWith({
//         where: { id: { in: equipmentIds } },
//         data: { isActive },
//       });
//     });
//   });

//   describe('EquipmentService integration', () => {
//     it('should handle service-level operations correctly', async () => {
//       const mockEquipment = [
//         {
//           id: 'equipment-1',
//           code: 'DUMBBELLS_5KG',
//           name: '5kg哑铃',
//           description: '适合初学者',
//           category: EquipmentCategory.STRENGTH,
//           isActive: true,
//           createdAt: new Date('2024-01-01'),
//           updatedAt: new Date('2024-01-01'),
//         },
//       ];

//       mockPrismaService.equipment.findMany.mockResolvedValue(mockEquipment);
//       mockPrismaService.equipment.count.mockResolvedValue(1);

//       const result = await service.findAll({ page: 1, pageSize: 10 });

//       expect(result.data).toHaveLength(1);
//       expect(result.data[0]).toMatchObject({
//         id: 'equipment-1',
//         code: 'DUMBBELLS_5KG',
//         name: '5kg哑铃',
//         category: EquipmentCategory.STRENGTH,
//         isActive: true,
//         createdAt: '2024-01-01T00:00:00.000Z',
//         updatedAt: '2024-01-01T00:00:00.000Z',
//       });
//       expect(result.pagination.total).toBe(1);
//     });

//     it('should throw ResponseError when equipment not found in service', async () => {
//       mockPrismaService.equipment.findUnique.mockResolvedValue(null);

//       await expect(service.findOne('non-existent-id')).rejects.toThrow(ResponseError);
//       await expect(service.findOne('non-existent-id')).rejects.toMatchObject({
//         code: ErrorCodes.EQUIPMENT.NOT_FOUND.code,
//       });
//     });

//     it('should create equipment successfully through service', async () => {
//       const createDto = {
//         code: 'NEW_EQUIPMENT',
//         name: 'New Equipment',
//         description: 'Description',
//         category: EquipmentCategory.STRENGTH,
//         isActive: true,
//       };

//       const mockCreatedEquipment = {
//         id: 'new-id',
//         ...createDto,
//         createdAt: new Date('2024-01-01'),
//         updatedAt: new Date('2024-01-01'),
//       };

//       // Mock DAO methods
//       mockPrismaService.equipment.count.mockResolvedValue(0); // code doesn't exist
//       mockPrismaService.equipment.create.mockResolvedValue(mockCreatedEquipment);

//       const result = await service.create(createDto);

//       expect(result).toMatchObject({
//         id: 'new-id',
//         code: 'NEW_EQUIPMENT',
//         name: 'New Equipment',
//         category: EquipmentCategory.STRENGTH,
//         isActive: true,
//         createdAt: '2024-01-01T00:00:00.000Z',
//         updatedAt: '2024-01-01T00:00:00.000Z',
//       });
//     });

//     it('should validate required fields when creating equipment', async () => {
//       const invalidDto = {
//         // Missing required 'code' and 'name' fields
//         description: 'Description only',
//       } as any;

//       await expect(service.create(invalidDto)).rejects.toThrow(ResponseError);
//       await expect(service.create(invalidDto)).rejects.toMatchObject({
//         code: ErrorCodes.COMMON.VALIDATION_ERROR.code,
//       });
//     });
//   });
// });

// /**
//  * 演示用法示例
//  */
// export class EquipmentUsageExample {
//   constructor(private equipmentDao: EquipmentDao) {}

//   /**
//    * 示例：获取力量训练器材
//    */
//   async getStrengthEquipment() {
//     try {
//       // 1. 获取所有力量训练器材
//       const strengthEquipment = await this.equipmentDao.findActiveEquipment('STRENGTH');

//       // 2. 按显示顺序分组
//       const sortedEquipment = strengthEquipment.sort((a, b) =>
//         (a.displayOrder || 999) - (b.displayOrder || 999)
//       );

//       return {
//         category: EquipmentCategory.STRENGTH,
//         equipment: sortedEquipment,
//         count: sortedEquipment.length,
//         summary: {
//           hasBasicEquipment: sortedEquipment.some(eq => eq.code.includes('DUMBBELLS')),
//           hasAdvancedEquipment: sortedEquipment.some(eq => eq.code.includes('BARBELL')),
//         },
//       };
//     } catch (error) {
//       console.error('Failed to get strength equipment:', error);
//       throw error;
//     }
//   }

//   /**
//    * 示例：分页获取器材并按分类统计
//    */
//   async getEquipmentWithCategoryStats(page: number = 1, pageSize: number = 20) {
//     try {
//       // 1. 分页获取器材
//       const paginatedResult = await this.equipmentDao.findEquipmentWithPagination(
//         page,
//         pageSize,
//         undefined, // 不筛选分类
//         false      // 不包含非活跃器材
//       );

//       // 2. 获取分类统计
//       const stats = await this.equipmentDao.getEquipmentStats();

//       // 3. 按分类分组当前页器材
//       const equipmentByCategory = paginatedResult.data.reduce((acc: any, equipment: any) => {
//         const category = equipment.category || 'OTHER';
//         if (!acc[category]) {
//           acc[category] = [];
//         }
//         acc[category].push(equipment);
//         return acc;
//       }, {});

//       return {
//         equipment: paginatedResult.data,
//         pagination: paginatedResult.pagination,
//         categoryBreakdown: equipmentByCategory,
//         overallStats: stats,
//         insights: {
//           mostPopularCategory: stats.categories.reduce((prev, curr) =>
//             prev.count > curr.count ? prev : curr
//           ),
//           totalCategories: stats.categories.length,
//           averageEquipmentPerCategory: Math.round(stats.active / stats.categories.length),
//         },
//       };
//     } catch (error) {
//       console.error('Failed to get equipment with category stats:', error);
//       throw error;
//     }
//   }

//   /**
//    * 示例：创建器材套装
//    */
//   async createEquipmentSet(setData: {
//     setName: string;
//     category: string;
//     equipmentList: Array<{
//       code: string;
//       name: string;
//       description?: string;
//       displayOrder?: number;
//     }>;
//   }) {
//     try {
//       const createdEquipment = [];
//       let displayOrder = 1;

//       // 1. 逐个创建器材
//       for (const equipment of setData.equipmentList) {
//         const equipmentData = {
//           ...equipment,
//           category: setData.category,
//           displayOrder: equipment.displayOrder || displayOrder++,
//           isActive: true,
//         };

//         const created = await this.equipmentDao.createEquipment(equipmentData);
//         createdEquipment.push(created);
//       }

//       // 2. 获取创建后的统计
//       const stats = await this.equipmentDao.getEquipmentStats();

//       return {
//         setName: setData.setName,
//         category: setData.category,
//         createdEquipment,
//         createdCount: createdEquipment.length,
//         updatedStats: stats,
//         message: `Successfully created ${createdEquipment.length} equipment in ${setData.setName} set`,
//       };
//     } catch (error) {
//       console.error('Failed to create equipment set:', error);
//       throw error;
//     }
//   }

//   /**
//    * 示例：器材维护操作
//    */
//   async performMaintenanceOperations() {
//     try {
//       // 1. 获取所有器材统计
//       const initialStats = await this.equipmentDao.getEquipmentStats();

//       // 2. 找出没有描述的器材
//       const allEquipment = await this.equipmentDao.findActiveEquipment();
//       const equipmentNeedingDescription = allEquipment.filter(eq => !eq.description);

//       // 3. 找出没有分类的器材
//       const equipmentNeedingCategory = allEquipment.filter(eq => !eq.category);

//       // 4. 找出显示顺序重复的器材
//       const displayOrders = allEquipment.map(eq => eq.displayOrder).filter(Boolean);
//       const duplicateOrders = displayOrders.filter((order, index) =>
//         displayOrders.indexOf(order) !== index
//       );

//       return {
//         initialStats,
//         maintenanceNeeded: {
//           missingDescription: {
//             count: equipmentNeedingDescription.length,
//             equipment: equipmentNeedingDescription.map(eq => ({ id: eq.id, code: eq.code, name: eq.name })),
//           },
//           missingCategory: {
//             count: equipmentNeedingCategory.length,
//             equipment: equipmentNeedingCategory.map(eq => ({ id: eq.id, code: eq.code, name: eq.name })),
//           },
//           duplicateDisplayOrders: {
//             orders: [...new Set(duplicateOrders)],
//             affectedCount: duplicateOrders.length,
//           },
//         },
//         recommendations: [
//           equipmentNeedingDescription.length > 0 && 'Add descriptions to equipment for better user experience',
//           equipmentNeedingCategory.length > 0 && 'Assign categories to uncategorized equipment',
//           duplicateOrders.length > 0 && 'Fix duplicate display orders for proper sorting',
//         ].filter(Boolean),
//       };
//     } catch (error) {
//       console.error('Failed to perform maintenance operations:', error);
//       throw error;
//     }
//   }
// }
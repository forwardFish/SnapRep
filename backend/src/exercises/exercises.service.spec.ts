import { Test, TestingModule } from '@nestjs/testing';
import { ExercisesService } from './exercises.service';
import { ExercisesDao } from './exercises.dao';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';

describe('ExercisesService', () => {
  let service: ExercisesService;
  let dao: ExercisesDao;

  const mockExercise = {
    id: 'ex-123',
    code: 'wall_chest_opener',
    name: 'Wall Chest Opener',
    primaryMuscle: 'CHEST',
    secondaryMuscles: ['SHOULDERS'],
    intentType: 'STRETCH',
    difficulty: 'GREEN',
    defaultDuration: 20,
    defaultSets: 1,
    durationType: 'TIME',
    description: {},
    demoImageUrl: null,
    demoVideoUrl: null,
    tags: ['wall', 'stretch', 'silent'],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  };

  const mockExercises = [
    mockExercise,
    {
      ...mockExercise,
      id: 'ex-456',
      code: 'chair_squat',
      name: 'Chair Squat',
      primaryMuscle: 'LEGS',
      intentType: 'STRENGTH'
    },
    {
      ...mockExercise,
      id: 'ex-789',
      code: 'core_plank',
      name: 'Core Plank',
      primaryMuscle: 'CORE',
      intentType: 'STRENGTH'
    }
  ];

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExercisesService,
        {
          provide: ExercisesDao,
          useValue: {
            findById: jest.fn(),
            findByCode: jest.fn(),
            findBySmartCriteria: jest.fn(),
            findByPage: jest.fn(),
            getExerciseStats: jest.fn(),
            count: jest.fn(),
          },
        },
        {
          provide: WorkoutRecommendationService,
          useValue: {
            generateQuickRecommendation: jest.fn(),
          },
        },
        {
          provide: ExerciseMatchingService,
          useValue: {
            replaceExercise: jest.fn(),
            getAlternatives: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ExercisesService>(ExercisesService);
    dao = module.get<ExercisesDao>(ExercisesDao);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findById', () => {
    it('should return exercise when found', async () => {
      jest.spyOn(dao, 'findById').mockResolvedValue(mockExercise);

      const result = await service.findById('ex-123');

      expect(result).toEqual(mockExercise);
      expect(dao.findById).toHaveBeenCalledWith('ex-123');
    });

    it('should return null when exercise not found', async () => {
      jest.spyOn(dao, 'findById').mockResolvedValue(null);

      const result = await service.findById('ex-nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('findByCode', () => {
    it('should return exercise when found by code', async () => {
      jest.spyOn(dao, 'findByCode').mockResolvedValue(mockExercise);

      const result = await service.findByCode('wall_chest_opener');

      expect(result).toEqual(mockExercise);
      expect(dao.findByCode).toHaveBeenCalledWith('wall_chest_opener');
    });

    it('should return null when code not found', async () => {
      jest.spyOn(dao, 'findByCode').mockResolvedValue(null);

      const result = await service.findByCode('invalid_code');

      expect(result).toBeNull();
    });
  });

  describe('findBySmartCriteria', () => {
    it('should find exercises matching multiple criteria', async () => {
      const criteria = {
        intent: 'STRETCH',
        equipment: ['wall'],
        scenario: 'office',
        targetMuscles: ['CHEST', 'BACK'],
        difficulty: 'GREEN',
        excludeIds: [],
        limit: 10
      };

      jest.spyOn(dao, 'findBySmartCriteria').mockResolvedValue(mockExercises);

      const result = await service.findBySmartCriteria(criteria);

      expect(result).toEqual(mockExercises);
      expect(dao.findBySmartCriteria).toHaveBeenCalledWith(criteria);
    });

    it('should exclude specified exercise IDs', async () => {
      const criteria = {
        intent: 'STRETCH',
        excludeIds: ['ex-123', 'ex-456']
      };

      jest.spyOn(dao, 'findBySmartCriteria').mockResolvedValue([mockExercises[2]]);

      const result = await service.findBySmartCriteria(criteria);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('ex-789');
    });

    it('should handle empty results', async () => {
      jest.spyOn(dao, 'findBySmartCriteria').mockResolvedValue([]);

      const result = await service.findBySmartCriteria({ intent: 'STRETCH' });

      expect(result).toEqual([]);
    });
  });

  describe('findWithPagination', () => {
    it('should return paginated results', async () => {
      const mockPagedResult = {
        data: mockExercises,
        pagination: {
          page: 1,
          pageSize: 10,
          total: 25,
          totalPages: 3,
          hasNextPage: true,
          hasPreviousPage: false
        }
      };

      jest.spyOn(dao, 'findByPage').mockResolvedValue(mockPagedResult as any);

      const result = await service.findWithPagination(1, 10, { intent: 'STRETCH', isActive: true });

      expect(result).toEqual(mockPagedResult);
      expect(result.data).toEqual(mockExercises);
      expect(result.pagination.page).toBe(1);
      expect(result.pagination.total).toBe(25);
      expect(dao.findByPage).toHaveBeenCalled();
    });

    it('should handle filters correctly', async () => {
      const filters = {
        intent: 'STRENGTH',
        difficulty: 'BLUE',
        primaryMuscle: 'LEGS',
        isActive: true
      };

      const mockPagedResult = {
        data: [mockExercises[1]],
        pagination: {
          page: 1,
          pageSize: 10,
          total: 1,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false
        }
      };

      jest.spyOn(dao, 'findByPage').mockResolvedValue(mockPagedResult as any);

      const result = await service.findWithPagination(1, 10, filters);

      expect(result.data).toHaveLength(1);
      expect(dao.findByPage).toHaveBeenCalled();
    });

    it('should use default pagination values', async () => {
      const mockPagedResult = {
        data: mockExercises,
        pagination: {
          page: 1,
          pageSize: 10,
          total: 3,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false
        }
      };

      jest.spyOn(dao, 'findByPage').mockResolvedValue(mockPagedResult as any);

      const result = await service.findWithPagination();

      expect(result).toBeDefined();
      expect(dao.findByPage).toHaveBeenCalled();
    });
  });

  describe('getStats', () => {
    it('should return exercise statistics', async () => {
      const mockStats = {
        total: 50,
        active: 45,
        inactive: 5,
        byDifficulty: {
          GREEN: 20,
          BLUE: 20,
          RED: 10
        },
        byIntent: {
          STRETCH: 15,
          STRENGTH: 20,
          RELAX: 10,
          MODERATE: 5
        }
      };

      jest.spyOn(dao, 'getExerciseStats').mockResolvedValue(mockStats);

      const result = await service.getStats();

      expect(result).toEqual(mockStats);
      expect(result.total).toBe(50);
      expect(result.active).toBe(45);
      expect(result.byIntent.STRETCH).toBe(15);
      expect(dao.getExerciseStats).toHaveBeenCalled();
    });

    it('should handle empty statistics', async () => {
      const emptyStats = {
        total: 0,
        active: 0,
        inactive: 0,
        byDifficulty: {},
        byIntent: {}
      };

      jest.spyOn(dao, 'getExerciseStats').mockResolvedValue(emptyStats);

      const result = await service.getStats();

      expect(result.total).toBe(0);
      expect(result.active).toBe(0);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from 'nestjs-prisma';
import { ExercisesDao } from './exercises.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { SupabaseApiService } from '../common/services/supabase-api.service';

describe('ExercisesDao', () => {
  let dao: ExercisesDao;
  let prismaService: PrismaService;

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
    updatedAt: new Date(),
    exerciseEquipment: [],
    exerciseScenarios: []
  } as any;

  const toSupabaseExercise = (exercise: any) => ({
    id: exercise.id,
    code: exercise.code,
    name: exercise.name,
    description: exercise.description,
    primary_muscle: exercise.primaryMuscle,
    secondary_muscles: exercise.secondaryMuscles || [],
    intent_type: Array.isArray(exercise.intentType) ? exercise.intentType : [exercise.intentType],
    difficulty: exercise.difficulty,
    default_duration: exercise.defaultDuration,
    default_sets: exercise.defaultSets,
    duration_type: exercise.durationType,
    demo_image_url: exercise.demoImageUrl,
    demo_video_url: exercise.demoVideoUrl,
    tags: exercise.tags || [],
    is_active: exercise.isActive,
    created_at: exercise.createdAt,
    updated_at: exercise.updatedAt,
  });

  const toDaoExercise = (exercise: any) => ({
    ...exercise,
    intentType: Array.isArray(exercise.intentType) ? exercise.intentType : [exercise.intentType],
  });

  let supabaseApiService: SupabaseApiService;

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
        ExercisesDao,
        {
          provide: PrismaService,
          useValue: {
            exercise: {
              findUnique: jest.fn(),
              findFirst: jest.fn(),
              findMany: jest.fn(),
              count: jest.fn(),
              groupBy: jest.fn(),
            },
            workoutSession: {
              findMany: jest.fn(),
            },
          },
        },
        {
          provide: SupabaseApiService,
          useValue: {
            getById: jest.fn(),
            getByField: jest.fn(),
            get: jest.fn(),
          },
        },
      ],
    }).compile();

    dao = module.get<ExercisesDao>(ExercisesDao);
    prismaService = module.get<PrismaService>(PrismaService);
    supabaseApiService = module.get<SupabaseApiService>(SupabaseApiService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findById', () => {
    it('should return exercise when found and active', async () => {
      jest.spyOn(supabaseApiService, 'getById').mockResolvedValue(toSupabaseExercise(mockExercise));

      const result = await dao.findById('ex-123');

      expect(result).toEqual(toDaoExercise(mockExercise));
      expect(supabaseApiService.getById).toHaveBeenCalled();
    });

    it('should return null when exercise not found', async () => {
      jest.spyOn(supabaseApiService, 'getById').mockResolvedValue(null);

      const result = await dao.findById('ex-nonexistent');

      expect(result).toBeNull();
    });

    it('should include inactive exercises when specified', async () => {
      const inactiveExercise = { ...mockExercise, isActive: false };
      jest.spyOn(supabaseApiService, 'getById').mockResolvedValue(toSupabaseExercise(inactiveExercise));

      const result = await dao.findById('ex-123', true);

      expect(result).toEqual(toDaoExercise(inactiveExercise));
      expect(result.isActive).toBe(false);
    });

    it('should throw ResponseError on database error', async () => {
      jest.spyOn(supabaseApiService, 'getById').mockRejectedValue(new Error('DB Error'));

      await expect(dao.findById('ex-123')).rejects.toThrow(ResponseError);
    });
  });

  describe('findByCode', () => {
    it('should return exercise when found by code', async () => {
      jest.spyOn(supabaseApiService, 'getByField').mockResolvedValue(toSupabaseExercise(mockExercise));

      const result = await dao.findByCode('wall_chest_opener');

      expect(result).toEqual(toDaoExercise(mockExercise));
      expect(supabaseApiService.getByField).toHaveBeenCalled();
    });

    it('should return null when code not found', async () => {
      jest.spyOn(supabaseApiService, 'getByField').mockResolvedValue(null);

      const result = await dao.findByCode('invalid_code');

      expect(result).toBeNull();
    });

    it('should throw ResponseError on database error', async () => {
      jest.spyOn(supabaseApiService, 'getByField').mockRejectedValue(new Error('DB Error'));

      await expect(dao.findByCode('wall_chest_opener')).rejects.toThrow(ResponseError);
    });
  });

  describe('findBySmartCriteria', () => {
    it('should find exercises by intent type', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue(mockExercises.map(toSupabaseExercise));

      const result = await dao.findBySmartCriteria({ intent: 'STRETCH' });

      expect(result).toEqual([toDaoExercise(mockExercises[0])]);
      expect(supabaseApiService.get).toHaveBeenCalled();
    });

    it('should filter by difficulty', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue([toSupabaseExercise(mockExercises[0])]);

      const result = await dao.findBySmartCriteria({ difficulty: 'GREEN' });

      expect(result).toHaveLength(1);
      expect(result[0].difficulty).toBe('GREEN');
    });

    it('should filter by equipment', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue([toSupabaseExercise(mockExercises[0])]);

      const result = await dao.findBySmartCriteria({ equipment: ['wall'] });

      expect(result).toBeDefined();
      expect(supabaseApiService.get).toHaveBeenCalled();
    });

    it('should filter by scenario', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue(mockExercises.map(toSupabaseExercise));

      const result = await dao.findBySmartCriteria({ scenario: 'office' });

      expect(result).toBeDefined();
      expect(supabaseApiService.get).toHaveBeenCalled();
    });

    it('should filter by target muscles', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue([toSupabaseExercise(mockExercises[0])]);

      const result = await dao.findBySmartCriteria({ targetMuscles: ['CHEST'] });

      expect(result).toBeDefined();
      expect(supabaseApiService.get).toHaveBeenCalled();
    });

    it('should exclude specified exercise IDs', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue([toSupabaseExercise(mockExercises[2])]);

      const result = await dao.findBySmartCriteria({
        intent: 'STRENGTH',
        excludeIds: ['ex-123', 'ex-456']
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('ex-789');
    });

    it('should respect limit parameter', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue(mockExercises.slice(0, 2).map(toSupabaseExercise));

      const result = await dao.findBySmartCriteria({ limit: 2 });

      expect(result.length).toBeLessThanOrEqual(2);
    });

    it('should handle empty results', async () => {
      jest.spyOn(supabaseApiService, 'get').mockResolvedValue([]);

      const result = await dao.findBySmartCriteria({ intent: 'NONEXISTENT' });

      expect(result).toEqual([]);
    });

    it('should throw ResponseError on database error', async () => {
      jest.spyOn(supabaseApiService, 'get').mockRejectedValue(new Error('DB Error'));

      await expect(dao.findBySmartCriteria({ intent: 'STRETCH' })).rejects.toThrow(ResponseError);
    });
  });

  describe('findRecentlyUsedByUser', () => {
    it('should return recently used exercise IDs', async () => {
      const mockSessions = [
        {
          id: 'session-1',
          sessionExercises: [
            { exerciseId: 'ex-123' },
            { exerciseId: 'ex-456' }
          ]
        },
        {
          id: 'session-2',
          sessionExercises: [
            { exerciseId: 'ex-789' },
            { exerciseId: 'ex-123' } // Duplicate
          ]
        }
      ];

      jest.spyOn(prismaService.workoutSession, 'findMany').mockResolvedValue(mockSessions as any);

      const result = await dao.findRecentlyUsedByUser('user-123', 7);

      expect(result).toContain('ex-123');
      expect(result).toContain('ex-456');
      expect(result).toContain('ex-789');
      // Should deduplicate ex-123
      expect(result.filter(id => id === 'ex-123').length).toBe(1);
    });

    it('should return empty array when no recent sessions', async () => {
      jest.spyOn(prismaService.workoutSession, 'findMany').mockResolvedValue([]);

      const result = await dao.findRecentlyUsedByUser('user-123', 7);

      expect(result).toEqual([]);
    });

    it('should throw ResponseError on database error', async () => {
      jest.spyOn(prismaService.workoutSession, 'findMany').mockRejectedValue(new Error('DB Error'));

      await expect(dao.findRecentlyUsedByUser('user-123')).rejects.toThrow(ResponseError);
    });
  });

  describe('getExerciseStats', () => {
    it('should return comprehensive exercise statistics', async () => {
      (prismaService.exercise.count as jest.Mock)
        .mockResolvedValueOnce(50) // total
        .mockResolvedValueOnce(45); // active

      (prismaService.exercise.groupBy as jest.Mock)
        .mockResolvedValueOnce([ // byDifficulty
          { difficulty: 'GREEN', _count: { id: 20 } },
          { difficulty: 'BLUE', _count: { id: 15 } },
          { difficulty: 'RED', _count: { id: 10 } }
        ]);

      (prismaService.exercise.findMany as jest.Mock).mockResolvedValue([
        { intentType: ['STRETCH'] },
        { intentType: ['STRENGTH'] },
        { intentType: ['STRENGTH', 'RELAX'] },
      ]);

      const result = await dao.getExerciseStats();

      expect(result.total).toBe(50);
      expect(result.active).toBe(45);
      expect(result.inactive).toBe(5);
      expect(result.byDifficulty.GREEN).toBe(20);
      expect(result.byIntent.STRETCH).toBe(1);
    });

    it('should handle empty database', async () => {
      (prismaService.exercise.count as jest.Mock)
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(0);

      (prismaService.exercise.groupBy as jest.Mock).mockResolvedValueOnce([]);
      (prismaService.exercise.findMany as jest.Mock).mockResolvedValue([]);

      const result = await dao.getExerciseStats();

      expect(result.total).toBe(0);
      expect(result.active).toBe(0);
      expect(result.inactive).toBe(0);
    });

    it('should throw ResponseError on database error', async () => {
      (prismaService.exercise.count as jest.Mock).mockRejectedValue(new Error('DB Error'));

      await expect(dao.getExerciseStats()).rejects.toThrow(ResponseError);
    });
  });

  describe('isCodeExists', () => {
    it('should return true when code exists', async () => {
      jest.spyOn(prismaService.exercise, 'count').mockResolvedValue(1);

      const result = await dao.isCodeExists('wall_chest_opener');

      expect(result).toBe(true);
    });

    it('should return false when code does not exist', async () => {
      jest.spyOn(prismaService.exercise, 'count').mockResolvedValue(0);

      const result = await dao.isCodeExists('nonexistent_code');

      expect(result).toBe(false);
    });

    it('should exclude specific ID when checking', async () => {
      jest.spyOn(prismaService.exercise, 'count').mockResolvedValue(0);

      const result = await dao.isCodeExists('wall_chest_opener', 'ex-123');

      expect(result).toBe(false);
      expect(prismaService.exercise.count).toHaveBeenCalled();
    });

    it('should throw ResponseError on database error', async () => {
      jest.spyOn(prismaService.exercise, 'count').mockRejectedValue(new Error('DB Error'));

      await expect(dao.isCodeExists('wall_chest_opener')).rejects.toThrow(ResponseError);
    });
  });
});

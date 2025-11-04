import { Test, TestingModule } from '@nestjs/testing';
import { ExercisesController } from './exercises.controller';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';
import { IntentType, Difficulty, PrimaryMuscle } from '../common/types/prisma-enums';

describe('ExercisesController', () => {
  let controller: ExercisesController;
  let workoutRecommendationService: WorkoutRecommendationService;
  let exerciseMatchingService: ExerciseMatchingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ExercisesController],
      providers: [
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

    controller = module.get<ExercisesController>(ExercisesController);
    workoutRecommendationService = module.get<WorkoutRecommendationService>(WorkoutRecommendationService);
    exerciseMatchingService = module.get<ExerciseMatchingService>(ExerciseMatchingService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('quickRecommendation', () => {
    it('should call workoutRecommendationService with DTO', async () => {
      const dto = {
        userId: 'user-123',
        intent: IntentType.STRETCH,
        equipment: ['wall'],
        scenario: 'office',
        targetMuscles: [PrimaryMuscle.CHEST],
        duration: 60,
        difficulty: Difficulty.GREEN,
        isOffline: false
      };

      const mockResult = {
        intent: IntentType.STRETCH,
        totalDuration: 60,
        difficulty: Difficulty.GREEN,
        exercises: [],
        alternatives: []
      };

      jest.spyOn(workoutRecommendationService, 'generateQuickRecommendation').mockResolvedValue(mockResult as any);

      const result = await controller.quickRecommendation(dto);

      expect(result).toBeDefined();
      expect(workoutRecommendationService.generateQuickRecommendation).toHaveBeenCalledWith(dto);
    });

    it('should handle errors from service', async () => {
      const dto = {
        intent: IntentType.STRETCH,
        difficulty: Difficulty.GREEN
      };

      jest.spyOn(workoutRecommendationService, 'generateQuickRecommendation')
        .mockRejectedValue(new Error('Service error'));

      await expect(controller.quickRecommendation(dto)).rejects.toThrow('Service error');
    });
  });

  describe('replaceExercise', () => {
    it('should call exerciseMatchingService with DTO', async () => {
      const dto = {
        sessionId: 'session-123',
        exercisePosition: 2,
        currentExerciseId: 'ex-456'
      };

      const mockResult = {
        success: true,
        newExercise: {
          id: 'ex-new-123',
          name: 'New Exercise',
          difficulty: Difficulty.BLUE,
          benefits: 'Better exercise'
        },
        message: 'Exercise replaced successfully'
      };

      jest.spyOn(exerciseMatchingService, 'replaceExercise').mockResolvedValue(mockResult as any);

      const result = await controller.replaceExercise(dto);

      expect(result).toBeDefined();
      expect(result.success).toBe(true);
      expect(exerciseMatchingService.replaceExercise).toHaveBeenCalledWith(dto);
    });

    it('should handle errors from service', async () => {
      const dto = {
        sessionId: 'session-123',
        exercisePosition: 1,
        currentExerciseId: 'ex-123'
      };

      jest.spyOn(exerciseMatchingService, 'replaceExercise')
        .mockRejectedValue(new Error('Replacement failed'));

      await expect(controller.replaceExercise(dto)).rejects.toThrow('Replacement failed');
    });
  });

  describe('getAlternatives', () => {
    it('should call exerciseMatchingService with query parameters', async () => {
      const query = {
        sessionId: 'session-123',
        equipment: ['wall'],
        targetMuscle: PrimaryMuscle.CHEST,
        limit: 10
      };

      const mockResult = {
        alternatives: [],
        filterSummary: {
          equipment: ['wall'],
          targetMuscle: PrimaryMuscle.CHEST,
          intensity: undefined
        }
      };

      jest.spyOn(exerciseMatchingService, 'getAlternatives').mockResolvedValue(mockResult as any);

      const result = await controller.getAlternatives(query);

      expect(result).toBeDefined();
      expect(exerciseMatchingService.getAlternatives).toHaveBeenCalledWith(query);
    });

    it('should handle errors from service', async () => {
      const query = {
        sessionId: 'session-123'
      };

      jest.spyOn(exerciseMatchingService, 'getAlternatives')
        .mockRejectedValue(new Error('Failed to get alternatives'));

      await expect(controller.getAlternatives(query)).rejects.toThrow('Failed to get alternatives');
    });
  });
});

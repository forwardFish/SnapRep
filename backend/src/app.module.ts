import { GraphQLModule } from '@nestjs/graphql';
import { forwardRef, Logger, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
// import { PrismaModule, loggingMiddleware } from 'nestjs-prisma';
// import { AppController } from './app.controller';
// import { AppService } from './app.service';
// import { AppResolver } from './app.resolver';
// import { AuthModule } from './auth/auth.module';
// import { UsersModule } from './users/users.module';
// import { PostsModule } from './posts/posts.module';
import { ScenariosModule } from './scenarios/scenarios.module';
import { EquipmentModule } from './equipment/equipment.module';
import { ScenarioEquipmentModule } from './scenario-equipment/scenario-equipment.module';
import { ExercisesModule } from './exercises/exercises.module';
import { WorkoutSessionsModule } from './workout-sessions/workout-sessions.module';
import { CardsModule } from './cards/cards.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { ThemeWeeksModule } from './theme-weeks/theme-weeks.module';
import { ChallengesModule } from './challenges/challenges.module';
import config from './common/configs/config';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { GqlConfigService } from './gql-config.service';
import { loggingMiddleware, PrismaModule } from 'nestjs-prisma';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';


@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [config] }),


    GraphQLModule.forRootAsync<ApolloDriverConfig>({
      driver: ApolloDriver,
      useClass: GqlConfigService,
    }),

    forwardRef(() => AuthModule),
    UsersModule,
    // PostsModule,
    ScenariosModule,
    EquipmentModule,
    ScenarioEquipmentModule,
    ExercisesModule,
    WorkoutSessionsModule,
    CardsModule,
    AnalyticsModule, // 新增 Analytics 模块
    ThemeWeeksModule, // 新增 ThemeWeeks 模块
    ChallengesModule, // 新增 Challenges 模块
    // TEMPORARY: Comment out PrismaModule until client generation issue is resolved
    PrismaModule.forRoot({
      isGlobal: true,
      prismaServiceOptions: {
        middlewares: [
          loggingMiddleware({
            logger: new Logger('Prisma'),
            logLevel: 'debug',
          }),
        ],
      },
    }),

  ],
  controllers: [],
  providers: [],
})
export class AppModule {}

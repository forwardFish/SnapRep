import { GraphQLModule } from '@nestjs/graphql';
import { Logger, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
// import { PrismaModule, loggingMiddleware } from 'nestjs-prisma';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AppResolver } from './app.resolver';
// import { AuthModule } from './auth/auth.module';
// import { UsersModule } from './users/users.module';
// import { PostsModule } from './posts/posts.module';
import { ScenariosModule } from './scenarios/scenarios.module';
import { EquipmentModule } from './equipment/equipment.module';
import config from './common/configs/config';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { GqlConfigService } from './gql-config.service';


@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [config] }),
    // TEMPORARY: Commenting out PrismaModule until Prisma client generation is fixed
    // PrismaModule.forRoot({
    //   isGlobal: true,
    //   prismaServiceOptions: {
    //     middlewares: [
    //       // configure your prisma middleware
    //       loggingMiddleware({
    //         logger: new Logger('PrismaMiddleware'),
    //         logLevel: 'log',
    //       }),
    //     ],
    //   },
    // }),

    GraphQLModule.forRootAsync<ApolloDriverConfig>({
      driver: ApolloDriver,
      useClass: GqlConfigService,
    }),

    // TEMPORARY: Comment out modules that depend on PrismaService
    // AuthModule,
    // UsersModule,
    // PostsModule,
    ScenariosModule,
    EquipmentModule,
    // TEMPORARY: Comment out PrismaModule until client generation issue is resolved
    // PrismaModule.forRoot({
    //   isGlobal: true, // ← 关键：全局可用
    // }),
    
  ],
  controllers: [AppController],
  providers: [AppService, AppResolver],
})
export class AppModule {}

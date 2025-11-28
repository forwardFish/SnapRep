import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { PrismaClientExceptionFilter } from 'nestjs-prisma';
import { join } from 'path';
import { AppModule } from './app.module';
import { ResponseErrorFilter, GlobalExceptionFilter } from './exception/response-error.filter';
import type {
  CorsConfig,
  NestConfig,
  SwaggerConfig,
} from './common/configs/config.interface';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Validation
  app.useGlobalPipes(new ValidationPipe());

  // enable shutdown hook
  app.enableShutdownHooks();

  // Prisma Client Exception Filter for unhandled exceptions
  const { httpAdapter } = app.get(HttpAdapterHost);
  app.useGlobalFilters(
    new ResponseErrorFilter(),           // 处理 ResponseError
    new PrismaClientExceptionFilter(httpAdapter),  // 处理 Prisma 异常
    new GlobalExceptionFilter(),         // 处理其他所有异常
  );

  const configService = app.get(ConfigService);
  const nestConfig = configService.get<NestConfig>('nest');
  const corsConfig = configService.get<CorsConfig>('cors');
  const swaggerConfig = configService.get<SwaggerConfig>('swagger');

  // Swagger Api
  if (swaggerConfig.enabled) {
    const options = new DocumentBuilder()
      .setTitle(swaggerConfig.title || 'Nestjs')
      .setDescription(swaggerConfig.description || 'The nestjs API description')
      .setVersion(swaggerConfig.version || '1.0')
      .addBearerAuth(
        {
          type: 'http',
          // scheme: 'bearer',
          bearerFormat: 'JWT',
          name: 'JWT',
          description: 'Enter JWT token',
          in: 'header',
        },
        'JWT-auth' // This name here is important for matching up with @ApiBearerAuth() in your controller!
      )
      .build();
    const document = SwaggerModule.createDocument(app, options);

    SwaggerModule.setup(swaggerConfig.path || 'api', app, document);
  }

  // Cors
  if (corsConfig.enabled) {
    app.enableCors();
  }

  // Static file serving for assets (videos, images, etc.)
  // This provides a fallback for direct file access
  // The AssetsController provides more control and validation
  const express = require('express');
  const assetsBasePath = join(__dirname, '..', 'asset');

  // Serve videos
  app.use('/api/v1/assets/videos', express.static(join(assetsBasePath, 'videos'), {
    setHeaders: (res, path) => {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Accept-Ranges', 'bytes');
      if (path.endsWith('.mp4')) {
        res.set('Content-Type', 'video/mp4');
      } else if (path.endsWith('.webm')) {
        res.set('Content-Type', 'video/webm');
      }
    },
  }));

  // Serve images
  app.use('/api/v1/assets/images', express.static(join(assetsBasePath, 'images'), {
    setHeaders: (res, path) => {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Cache-Control', 'public, max-age=604800'); // 7 days
      const ext = path.split('.').pop()?.toLowerCase();
      if (ext === 'jpg' || ext === 'jpeg') {
        res.set('Content-Type', 'image/jpeg');
      } else if (ext === 'png') {
        res.set('Content-Type', 'image/png');
      } else if (ext === 'webp') {
        res.set('Content-Type', 'image/webp');
      }
    },
  }));

  await app.listen(process.env.PORT || nestConfig.port || 3000);
}
bootstrap();

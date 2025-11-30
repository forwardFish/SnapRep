import {
  Controller,
  Get,
  Param,
  Res,
  NotFoundException,
  StreamableFile,
  Header,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { Response } from 'express';
import { createReadStream, existsSync, statSync } from 'fs';
import { join } from 'path';
import { logger } from '../common/logger/logger';

/**
 * Assets Controller
 * Unified controller for serving all static assets:
 * - Videos (training demonstration videos)
 * - Images (thumbnails, scenario images, exercise images)
 * - Other media files
 */
@ApiTags('Assets')
@Controller('api/v1/assets')
export class AssetsController {
  private readonly assetsBasePath = join(__dirname, '..', '..', 'asset');

  /**
   * Get video file
   * GET /api/v1/assets/videos/:filename
   */
  @Get('videos/:filename')
  @ApiOperation({
    summary: 'Get exercise video',
    description: 'Stream exercise demonstration video with support for range requests',
  })
  @ApiParam({
    name: 'filename',
    description: 'Video filename (e.g., wall_chest_opener.mp4)',
    example: 'wall_chest_opener.mp4',
  })
  @ApiResponse({
    status: 200,
    description: 'Video file successfully streamed',
  })
  @ApiResponse({
    status: 404,
    description: 'Video file not found',
  })
  @Header('Accept-Ranges', 'bytes')
  async getVideo(
    @Param('filename') filename: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    logger.info(`Serving video: ${filename}`);
    
    return this.serveFile('videos', filename, res, {
      cacheMaxAge: 31536000, // 1 year for videos
    });
  }

  /**
   * Get image file
   * GET /api/v1/assets/images/:filename
   */
  @Get('images/:filename')
  @ApiOperation({
    summary: 'Get image file',
    description: 'Get image file (thumbnails, scenario images, exercise images, etc.)',
  })
  @ApiParam({
    name: 'filename',
    description: 'Image filename (e.g., exercise_thumbnail.jpg)',
    example: 'exercise_thumbnail.jpg',
  })
  @ApiResponse({
    status: 200,
    description: 'Image file successfully retrieved',
  })
  @ApiResponse({
    status: 404,
    description: 'Image file not found',
  })
  async getImage(
    @Param('filename') filename: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    logger.info(`Serving image: ${filename}`);
    return this.serveFile('images', filename, res, {
      cacheMaxAge: 604800, // 7 days for images
    });
  }

  /**
   * Check if video file exists
   * GET /api/v1/assets/videos/check/:filename
   */
  @Get('videos/check/:filename')
  @ApiOperation({
    summary: 'Check if video exists',
    description: 'Check if a video file exists without downloading it',
  })
  @ApiParam({
    name: 'filename',
    description: 'Video filename to check',
    example: 'wall_chest_opener.mp4',
  })
  @ApiResponse({
    status: 200,
    description: 'Video exists',
    schema: {
      type: 'object',
      properties: {
        exists: { type: 'boolean', example: true },
        filename: { type: 'string', example: 'wall_chest_opener.mp4' },
        size: { type: 'number', example: 1048576 },
        url: {
          type: 'string',
          example: 'http://localhost:3000/api/v1/assets/videos/wall_chest_opener.mp4',
        },
      },
    },
  })
  @ApiResponse({
    status: 404,
    description: 'Video not found',
  })
  async checkVideo(@Param('filename') filename: string) {
    logger.info(`Checking video: ${filename}`);
    return this.checkFile('videos', filename);
  }

  /**
   * Check if image file exists
   * GET /api/v1/assets/images/check/:filename
   */
  @Get('images/check/:filename')
  @ApiOperation({
    summary: 'Check if image exists',
    description: 'Check if an image file exists without downloading it',
  })
  @ApiParam({
    name: 'filename',
    description: 'Image filename to check',
    example: 'exercise_thumbnail.jpg',
  })
  @ApiResponse({
    status: 200,
    description: 'Image exists',
  })
  @ApiResponse({
    status: 404,
    description: 'Image not found',
  })
  async checkImage(@Param('filename') filename: string) {
    logger.info(`Checking image: ${filename}`);
    return this.checkFile('images', filename);
  }

  /**
   * Private helper: Serve file from asset directory
   */
  private async serveFile(
    subFolder: string,
    filename: string,
    res: Response,
    options: { cacheMaxAge?: number } = {},
  ): Promise<StreamableFile> {
    // Validate filename to prevent directory traversal attacks
    if (
      filename.includes('..') ||
      filename.includes('/') ||
      filename.includes('\\')
    ) {
      logger.error(`Invalid filename attempted: ${filename}`);
      throw new NotFoundException('File not found');
    }

    const filePath = join(this.assetsBasePath, subFolder, filename);

    // Check if file exists
    if (!existsSync(filePath)) {
      logger.warn(`File not found: ${filePath}`);
      throw new NotFoundException(`File '${filename}' not found`);
    }

    // Get file stats
    const stat = statSync(filePath);
    const fileSize = stat.size;

    // Determine content type
    const ext = filename.split('.').pop()?.toLowerCase();
    const contentType = this.getContentType(ext);

    // Set response headers
    res.set({
      'Content-Type': contentType,
      'Content-Length': fileSize,
      'Cache-Control': `public, max-age=${options.cacheMaxAge || 86400}`,
    });

    logger.info(`Serving file: ${subFolder}/${filename} (${fileSize} bytes)`);

    // Create a readable stream and return as StreamableFile
    const file = createReadStream(filePath);
    return new StreamableFile(file);
  }

  /**
   * Private helper: Check if file exists
   */
  private async checkFile(subFolder: string, filename: string) {
    // Validate filename
    if (
      filename.includes('..') ||
      filename.includes('/') ||
      filename.includes('\\')
    ) {
      throw new NotFoundException('File not found');
    }

    const filePath = join(this.assetsBasePath, subFolder, filename);
    const exists = existsSync(filePath);

    if (!exists) {
      throw new NotFoundException(`File '${filename}' not found`);
    }

    const stat = statSync(filePath);

    return {
      exists: true,
      filename,
      size: stat.size,
      url: `/api/v1/assets/${subFolder}/${filename}`,
    };
  }

  /**
   * Private helper: Get content type based on file extension
   */
  private getContentType(ext: string | undefined): string {
    const contentTypeMap: Record<string, string> = {
      // Video formats
      mp4: 'video/mp4',
      webm: 'video/webm',
      avi: 'video/x-msvideo',
      mov: 'video/quicktime',

      // Image formats
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      png: 'image/png',
      gif: 'image/gif',
      webp: 'image/webp',
      svg: 'image/svg+xml',
      bmp: 'image/bmp',
      ico: 'image/x-icon',

      // Default
      default: 'application/octet-stream',
    };

    return contentTypeMap[ext?.toLowerCase() || 'default'] || contentTypeMap.default;
  }
}

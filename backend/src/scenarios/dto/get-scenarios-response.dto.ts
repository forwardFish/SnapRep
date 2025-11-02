import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ScenarioResponseDto {
  @ApiProperty({
    description: '场景ID',
    example: 'scenario-001',
  })
  id: string;

  @ApiProperty({
    description: '场景代码',
    example: 'office',
  })
  code: string;

  @ApiProperty({
    description: '场景名称',
    example: 'Office',
  })
  name: string;

  @ApiPropertyOptional({
    description: '噪音容忍度',
    example: 'SILENT',
  })
  noiseTolerance?: string;

  @ApiPropertyOptional({
    description: '空间需求',
    example: 'SMALL',
  })
  spaceRequirement?: string;

  @ApiPropertyOptional({
    description: '图标URL',
    example: 'https://storage.supabase.co/icons/office.svg',
  })
  iconUrl?: string;

  @ApiProperty({
    description: '是否活跃',
    example: true,
  })
  isActive: boolean;

  @ApiProperty({
    description: '创建时间',
    example: '2024-10-30T10:30:00Z',
  })
  createdAt: Date;

  @ApiProperty({
    description: '更新时间',
    example: '2024-10-30T10:30:00Z',
  })
  updatedAt: Date;
}

export class PaginationDto {
  @ApiProperty({
    description: '总记录数',
    example: 50,
  })
  total: number;

  @ApiProperty({
    description: '当前页码',
    example: 1,
  })
  page: number;

  @ApiProperty({
    description: '每页数量',
    example: 10,
  })
  pageSize: number;

  @ApiProperty({
    description: '总页数',
    example: 5,
  })
  totalPages: number;

  @ApiProperty({
    description: '是否有下一页',
    example: true,
  })
  hasNextPage: boolean;

  @ApiProperty({
    description: '是否有上一页',
    example: false,
  })
  hasPreviousPage: boolean;
}

export class GetScenariosResponseDto {
  @ApiProperty({
    description: '场景列表',
    type: [ScenarioResponseDto],
  })
  data: ScenarioResponseDto[];

  @ApiProperty({
    description: '分页信息',
    type: PaginationDto,
  })
  pagination: PaginationDto;
}
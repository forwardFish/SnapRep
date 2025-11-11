import { Module } from '@nestjs/common';
import { UsersResolver } from './users.resolver';
import { UsersService } from './users.service';
import { PasswordService } from '../auth/password.service';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [CommonModule],
  providers: [UsersResolver, UsersService, PasswordService],
  exports: [
      UsersResolver,
      UsersService
    ],
})
export class UsersModule {}

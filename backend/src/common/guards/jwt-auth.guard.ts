import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { GqlExecutionContext } from '@nestjs/graphql';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  getRequest(context: ExecutionContext) {
    // 支持 REST API 和 GraphQL
    const ctx = GqlExecutionContext.create(context);

    // 如果是 GraphQL context
    if (ctx.getType() === 'graphql') {
      return ctx.getContext().req;
    }

    // 如果是 REST API context
    return context.switchToHttp().getRequest();
  }
}
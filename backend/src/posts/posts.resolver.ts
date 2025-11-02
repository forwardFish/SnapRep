import { PrismaService } from 'nestjs-prisma';
import {
  Resolver,
  Query,
  Parent,
  Args,
  ResolveField,
  Subscription,
  Mutation,
} from '@nestjs/graphql';
import { findManyCursorConnection } from '@devoxa/prisma-relay-cursor-connection';
import { PubSub } from 'graphql-subscriptions';
import { forwardRef, Inject, UseGuards } from '@nestjs/common';
import { PaginationArgs } from '../common/pagination/pagination.args';
import { UserEntity } from '../common/decorators/user.decorator';
import { User } from '../users/models/user.model';
import { GqlAuthGuard } from '../auth/gql-auth.guard';
import { PostIdArgs } from './args/post-id.args';
import { UserIdArgs } from './args/user-id.args';
import { Post } from './models/post.model';
import { PostConnection } from './models/post-connection.model';
import { PostOrder } from './dto/post-order.input';
import { CreatePostInput } from './dto/createPost.input';

const pubSub = new PubSub();

@Resolver(() => Post)
export class PostsResolver {

  @Inject(forwardRef(() => PrismaService))
  private prisma: PrismaService
  constructor() {}

  @Subscription(() => Post)
  postCreated() {
    return pubSub.asyncIterator('postCreated');
  }

  @UseGuards(GqlAuthGuard)
  @Mutation(() => Post)
  async createPost(
    @UserEntity() user: User,
    @Args('data') data: CreatePostInput,
  ) {
    // TODO: Re-enable after Post model is added to schema
    throw new Error('Post creation temporarily disabled during migration');
  }

  @Query(() => PostConnection)
  async publishedPosts(
    @Args() { after, before, first, last }: PaginationArgs,
    @Args({ name: 'query', type: () => String, nullable: true })
    query: string,
    @Args({
      name: 'orderBy',
      type: () => PostOrder,
      nullable: true,
    })
    orderBy: PostOrder,
  ) {
    // TODO: Re-enable after Post model is added to schema
    throw new Error('Post queries temporarily disabled during migration');
  }

  @Query(() => [Post])
  userPosts(@Args() id: UserIdArgs) {
    // TODO: Re-enable after Post model is added to schema
    throw new Error('User posts query temporarily disabled during migration');
  }

  @Query(() => Post)
  async post(@Args() id: PostIdArgs) {
    // TODO: Re-enable after Post model is added to schema
    throw new Error('Post query temporarily disabled during migration');
  }

  @ResolveField('author', () => User)
  async author(@Parent() post: Post) {
    // TODO: Re-enable after Post model is added to schema
    throw new Error('Post author resolution temporarily disabled during migration');
  }
}

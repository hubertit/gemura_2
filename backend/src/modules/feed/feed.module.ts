import { Module } from '@nestjs/common';
import { PostsModule } from './posts/posts.module';
import { StoriesModule } from './stories/stories.module';
import { CommentsModule } from './comments/comments.module';
import { InteractionsModule } from './interactions/interactions.module';
import { RelationshipsModule } from './relationships/relationships.module';

@Module({
  imports: [PostsModule, StoriesModule, CommentsModule, InteractionsModule, RelationshipsModule],
  exports: [PostsModule, StoriesModule, CommentsModule, InteractionsModule, RelationshipsModule],
})
export class FeedModule {}


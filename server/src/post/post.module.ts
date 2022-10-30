import { Module } from '@nestjs/common';
import { PostService } from './service/post.service';
import { PostController } from './controller/post.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MarkdownPost, PostImage } from './entities';
import { MulterModule } from "@nestjs/platform-express"
import { MulterPostConfig } from '@/util/multer-post';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      MarkdownPost,
      PostImage,
    ]),

    MulterModule.registerAsync({
      useClass: MulterPostConfig,
    })
  ],
  controllers: [PostController],
  providers: [PostService]
})
export class PostModule { }

import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseInterceptors,
  UploadedFile,
  Bind,
  UploadedFiles,
  StreamableFile,
  Res,
  Header,
} from '@nestjs/common';
import { PostService } from '../service/post.service';
import { CreatePostDto } from '../dto/create-post.dto';
import { UpdatePostDto } from '../dto/update-post.dto';
import { FileFieldsInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { createReadStream } from 'fs';
import { join } from 'path';

@Controller('post')
export class PostController {
  constructor(private readonly postService: PostService) { }
  @Post()
  // @UseInterceptors(FilesInterceptor('files', 2, MulterOption)) //MulterOption
  @UseInterceptors(FileFieldsInterceptor([
      {name : "images", maxCount : 5},
      {name : "md", maxCount : 1}
  ]))
  create(
    @Body() createPostDto: CreatePostDto,
    @UploadedFiles()
    files : { images ?: Array<Express.Multer.File>, md ?: Array<Express.Multer.File>}
  ) {
    console.log("hello localhost/post")
    return this.postService.create(createPostDto, files);
    // interceptor, uploaded 둘 다 file/files 구분한다.
  }

  @Get(':id')
  // @Header('Content-Type', 'image/jpeg')
  findOne(
    @Param('id') id: number
  ) { //: StreamableFile
    // book_1666524175087-876151646.png
    //docker_1666534732389-598109478.txt
    const file = createReadStream(join(process.cwd(), `markdown\docker_1666534732389-598109478.txt`));
    console.log(file.path);
    console.log(id);
    // return new StreamableFile(file);
    return this.postService.findOne(id);
  }

  @Get('/all')
  findAll() {
    return this.postService.findAll();
  }
  
  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePostDto: UpdatePostDto) {
    return this.postService.update(+id, updatePostDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.postService.remove(+id);
  }
}

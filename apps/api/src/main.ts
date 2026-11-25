import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();

  const config = new DocumentBuilder().setTitle('API').setVersion('0.1').build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, config));

  // Cloud Run fournit le port dans PORT et exige d'écouter sur 0.0.0.0
  await app.listen(process.env.PORT ?? 8080, '0.0.0.0');
}
bootstrap();

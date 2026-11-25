import { Module } from '@nestjs/common';
import { HealthController } from './app.service';

@Module({
  imports: [],
  controllers: [HealthController]
})
export class AppModule {}

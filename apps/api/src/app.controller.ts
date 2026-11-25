
import {
  Controller,
  Get,
  ServiceUnavailableException,
} from '@nestjs/common';

import pg from 'pg';

const { Pool } = pg;

// Variables fournies par Terraform sur Cloud Run (DB_HOST = socket Cloud SQL)
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER ?? 'app',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME ?? 'app',
  max: 2,
  connectionTimeoutMillis: 3000,
});

@Controller()
export class AppController {
  @Get()
  getHello(): string {
    return 'Hello World!';
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }

  @Get('health/db')
  async healthDb() {
    try {
      await pool.query('SELECT 1');
      return { status: 'ok' };
    } catch {
      throw new ServiceUnavailableException({
        status: 'db_unreachable',
      });
    }
  }
}

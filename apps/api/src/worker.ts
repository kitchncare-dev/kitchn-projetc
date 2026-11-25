import { Worker } from 'bullmq';

const worker = new Worker(
  'demo',
  async (job) => {
    console.log(`Job reçu : ${job.id}`, job.data);
  },
  {
    connection: {
      host: process.env.REDIS_HOST ?? 'localhost',
      port: Number(process.env.REDIS_PORT ?? 6379),
    },
  },
);

worker.on('ready', () => console.log('Worker prêt'));

process.on('SIGTERM', async () => {
  await worker.close();
  process.exit(0);
});

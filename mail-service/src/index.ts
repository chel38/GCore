import 'dotenv/config'
import { loadConfig } from './config.js'
import { createMailer } from './mailer.js'
import { logger } from './logger.js'
import { buildServer } from './server.js'

const config = loadConfig()
const mailer = await createMailer(config)
const app = buildServer(config, mailer)

async function shutdown(signal: string): Promise<void> {
  logger.info(`shutdown requested signal=${signal}`)
  await app.close()
  mailer.close()
}

process.once('SIGINT', () => void shutdown('SIGINT'))
process.once('SIGTERM', () => void shutdown('SIGTERM'))

await app.listen({ host: config.host, port: config.port })
logger.info(`service started host=${config.host} port=${config.port}`)

import { createHash, timingSafeEqual } from 'node:crypto'
import Fastify, { type FastifyInstance } from 'fastify'
import type { MailServiceConfig } from './config.js'
import { logger, maskEmail } from './logger.js'
import type { MailSender } from './mailer.js'
import { FixedWindowRateLimiter } from './rate-limit.js'
import { validateVerificationRequest } from './validation.js'

function tokenMatches(actual: unknown, expected: string): boolean {
  if (typeof actual !== 'string') return false
  const left = createHash('sha256').update(actual).digest()
  const right = createHash('sha256').update(expected).digest()
  return timingSafeEqual(left, right)
}

export function buildServer(config: MailServiceConfig, mailer: MailSender): FastifyInstance {
  const app = Fastify({ bodyLimit: 8192, logger: false })
  const limiter = new FixedWindowRateLimiter(config.rateLimit.windowMs, config.rateLimit.maximum)

  app.get('/health', async () => ({
    ok: true,
    service: 'gcore-mail-service',
    status: 'healthy',
  }))

  app.post('/v1/email/verification', async (request, reply) => {
    if (!tokenMatches(request.headers['x-gcore-mail-token'], config.token)) {
      logger.warn(`unauthorized request requestId=${request.id}`)
      return reply.code(401).send({ ok: false, code: 'MAIL-UNAUTHORIZED' })
    }

    if (!limiter.allow()) {
      logger.warn(`rate limit exceeded requestId=${request.id}`)
      return reply.code(429).send({ ok: false, code: 'MAIL-RATE-LIMITED' })
    }

    const payload = validateVerificationRequest(request.body)
    if (!payload) return reply.code(400).send({ ok: false, code: 'MAIL-INVALID-REQUEST' })

    const startedAt = Date.now()
    try {
      await mailer.sendVerification(payload)
      logger.info(
        `verification sent type=${payload.type} recipient=${maskEmail(payload.email)} requestId=${request.id} durationMs=${Date.now() - startedAt}`,
      )
      return reply.code(202).send({ ok: true, status: 'sent' })
    } catch (error) {
      const category = error instanceof Error && error.message === 'MAIL-SMTP-TIMEOUT'
        ? 'timeout'
        : 'send-failed'
      logger.error(`SMTP ${category} requestId=${request.id} durationMs=${Date.now() - startedAt}`)
      return reply.code(502).send({ ok: false, code: 'MAIL-SMTP-FAILED' })
    }
  })

  app.setErrorHandler((error, _request, reply) => {
    const statusCode = error && typeof error === 'object' && 'statusCode' in error
      ? error.statusCode
      : undefined
    if (statusCode === 413) {
      return reply.code(413).send({ ok: false, code: 'MAIL-BODY-TOO-LARGE' })
    }
    if (statusCode === 400) {
      return reply.code(400).send({ ok: false, code: 'MAIL-INVALID-REQUEST' })
    }
    logger.error('HTTP request failed')
    return reply.code(500).send({ ok: false, code: 'MAIL-INTERNAL' })
  })

  return app
}

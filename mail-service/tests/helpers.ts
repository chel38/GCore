import path from 'node:path'
import type { MailServiceConfig } from '../src/config.js'
import type { MailSender } from '../src/mailer.js'
import type { VerificationRequest } from '../src/validation.js'

export function testConfig(overrides: Partial<MailServiceConfig> = {}): MailServiceConfig {
  return {
    host: '127.0.0.1',
    port: 8091,
    token: 'test-token-with-at-least-thirty-two-characters',
    smtp: {
      host: '127.0.0.1',
      port: 1025,
      secure: false,
      connectionTimeoutMs: 100,
      socketTimeoutMs: 100,
      sendTimeoutMs: 100,
    },
    from: { name: 'GCore', address: 'no-reply@gcore.local' },
    rateLimit: { windowMs: 60_000, maximum: 30 },
    templatesDirectory: path.resolve(process.cwd(), 'templates'),
    ...overrides,
  }
}

export function fakeMailer(send?: (request: VerificationRequest) => Promise<void>): MailSender {
  return {
    sendVerification: send ?? (async () => undefined),
    verify: async () => true,
    close: () => undefined,
  }
}

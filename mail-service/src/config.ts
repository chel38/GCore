import path from 'node:path'
import { fileURLToPath } from 'node:url'

export interface MailServiceConfig {
  host: '127.0.0.1'
  port: number
  token: string
  smtp: {
    host: string
    port: number
    secure: boolean
    user?: string
    password?: string
    connectionTimeoutMs: number
    socketTimeoutMs: number
    sendTimeoutMs: number
  }
  from: { name: string; address: string }
  rateLimit: { windowMs: number; maximum: number }
  templatesDirectory: string
}

function integer(env: NodeJS.ProcessEnv, name: string, fallback: number, minimum: number): number {
  const raw = env[name]
  const value = raw === undefined || raw === '' ? fallback : Number(raw)

  if (!Number.isInteger(value) || value < minimum) {
    throw new Error(`MAIL-CONFIG-INVALID: ${name}`)
  }

  return value
}

function required(env: NodeJS.ProcessEnv, name: string): string {
  const value = env[name]?.trim()
  if (!value) throw new Error(`MAIL-CONFIG-MISSING: ${name}`)
  return value
}

function boolean(env: NodeJS.ProcessEnv, name: string, fallback: boolean): boolean {
  const raw = env[name]
  if (raw === undefined || raw === '') return fallback
  if (raw === 'true') return true
  if (raw === 'false') return false
  throw new Error(`MAIL-CONFIG-INVALID: ${name}`)
}

export function loadConfig(
  env: NodeJS.ProcessEnv = process.env,
  cwd?: string,
): MailServiceConfig {
  const host = env.MAIL_SERVICE_HOST?.trim() || '127.0.0.1'
  if (host !== '127.0.0.1') {
    throw new Error('MAIL-CONFIG-UNSAFE-HOST: MAIL_SERVICE_HOST must be 127.0.0.1')
  }

  const token = required(env, 'MAIL_SERVICE_TOKEN')
  if (token.length < 32) throw new Error('MAIL-CONFIG-WEAK-TOKEN: minimum length is 32')

  const smtpUser = env.SMTP_USER?.trim()
  const smtpPassword = env.SMTP_PASSWORD
  if ((smtpUser && !smtpPassword) || (!smtpUser && smtpPassword)) {
    throw new Error('MAIL-CONFIG-INVALID: SMTP_USER and SMTP_PASSWORD must be set together')
  }

  return {
    host,
    port: integer(env, 'MAIL_SERVICE_PORT', 8091, 1),
    token,
    smtp: {
      host: required(env, 'SMTP_HOST'),
      port: integer(env, 'SMTP_PORT', 1025, 1),
      secure: boolean(env, 'SMTP_SECURE', false),
      ...(smtpUser && smtpPassword ? { user: smtpUser, password: smtpPassword } : {}),
      connectionTimeoutMs: integer(env, 'SMTP_CONNECTION_TIMEOUT_MS', 5000, 100),
      socketTimeoutMs: integer(env, 'SMTP_SOCKET_TIMEOUT_MS', 10000, 100),
      sendTimeoutMs: integer(env, 'SMTP_SEND_TIMEOUT_MS', 12000, 100),
    },
    from: {
      name: env.MAIL_FROM_NAME?.trim() || 'GCore',
      address: required(env, 'MAIL_FROM_ADDRESS'),
    },
    rateLimit: {
      windowMs: integer(env, 'RATE_LIMIT_WINDOW_MS', 60_000, 1000),
      maximum: integer(env, 'RATE_LIMIT_MAX', 30, 1),
    },
    templatesDirectory: cwd
      ? path.resolve(cwd, 'templates')
      : fileURLToPath(new URL('../templates', import.meta.url)),
  }
}

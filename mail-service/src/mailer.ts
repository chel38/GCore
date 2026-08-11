import { readFile } from 'node:fs/promises'
import path from 'node:path'
import nodemailer from 'nodemailer'
import type { MailServiceConfig } from './config.js'
import type { VerificationRequest } from './validation.js'

export interface MailSender {
  sendVerification(request: VerificationRequest): Promise<void>
  verify(): Promise<boolean>
  close(): void
}

interface Templates { html: string; text: string }

function subject(type: VerificationRequest['type']): string {
  return type === 'registration' ? 'GCore — подтверждение регистрации' : 'GCore — подтверждение входа'
}

function title(type: VerificationRequest['type']): string {
  return type === 'registration' ? 'Подтверждение регистрации' : 'Подтверждение входа'
}

function description(type: VerificationRequest['type']): string {
  return type === 'registration'
    ? 'Введите этот код на сервере GCore. Если вы не создавали аккаунт, просто проигнорируйте письмо.'
    : 'Обнаружен вход с нового сетевого адреса. Если это были не вы, никому не сообщайте код.'
}

export function renderVerification(template: string, request: VerificationRequest): string {
  return template
    .replaceAll('{{title}}', title(request.type))
    .replaceAll('{{description}}', description(request.type))
    .replaceAll('{{code}}', request.code)
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  let timer: NodeJS.Timeout | undefined
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error('MAIL-SMTP-TIMEOUT')), timeoutMs)
  })

  try {
    return await Promise.race([promise, timeout])
  } finally {
    if (timer) clearTimeout(timer)
  }
}

export async function createMailer(config: MailServiceConfig): Promise<MailSender> {
  const [html, text] = await Promise.all([
    readFile(path.join(config.templatesDirectory, 'verification.html'), 'utf8'),
    readFile(path.join(config.templatesDirectory, 'verification.txt'), 'utf8'),
  ])
  const templates: Templates = { html, text }
  const transport = nodemailer.createTransport({
    host: config.smtp.host,
    port: config.smtp.port,
    secure: config.smtp.secure,
    connectionTimeout: config.smtp.connectionTimeoutMs,
    socketTimeout: config.smtp.socketTimeoutMs,
    ...(config.smtp.user ? { auth: { user: config.smtp.user, pass: config.smtp.password } } : {}),
  })

  return {
    async sendVerification(request): Promise<void> {
      await withTimeout(transport.sendMail({
        from: { name: config.from.name, address: config.from.address },
        to: request.email,
        subject: subject(request.type),
        html: renderVerification(templates.html, request),
        text: renderVerification(templates.text, request),
      }), config.smtp.sendTimeoutMs)
    },
    async verify(): Promise<boolean> {
      try {
        await withTimeout(transport.verify(), config.smtp.connectionTimeoutMs)
        return true
      } catch {
        return false
      }
    },
    close(): void {
      transport.close()
    },
  }
}

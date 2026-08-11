export type VerificationType = 'registration' | 'authentication'

export interface VerificationRequest {
  email: string
  code: string
  type: VerificationType
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const ALLOWED_KEYS = new Set(['email', 'code', 'type'])

export function validateVerificationRequest(value: unknown): VerificationRequest | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const body = value as Record<string, unknown>
  if (Object.keys(body).some((key) => !ALLOWED_KEYS.has(key))) return null
  if (Object.keys(body).length !== ALLOWED_KEYS.size) return null
  if (typeof body.email !== 'string' || body.email.length < 5 || body.email.length > 254) return null
  if (!EMAIL.test(body.email) || /[\u0000-\u001f\u007f]/.test(body.email)) return null
  if (typeof body.code !== 'string' || !/^\d{6}$/.test(body.code)) return null
  if (body.type !== 'registration' && body.type !== 'authentication') return null

  return { email: body.email.toLowerCase(), code: body.code, type: body.type }
}

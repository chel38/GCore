import { afterEach, describe, expect, it } from 'vitest'
import { buildServer } from '../src/server.js'
import { fakeMailer, testConfig } from './helpers.js'

const servers: ReturnType<typeof buildServer>[] = []
afterEach(async () => Promise.all(servers.splice(0).map((server) => server.close())))

const validBody = { email: 'user+tag@example.com', code: '483921', type: 'registration' }

describe('mail HTTP security boundary', () => {
  it.each([undefined, 'wrong-token'])('rejects missing or wrong token', async (token) => {
    const server = buildServer(testConfig(), fakeMailer())
    servers.push(server)
    const response = await server.inject({
      method: 'POST',
      url: '/v1/email/verification',
      headers: token ? { 'x-gcore-mail-token': token } : {},
      payload: validBody,
    })
    expect(response.statusCode).toBe(401)
    expect(response.json()).toEqual({ ok: false, code: 'MAIL-UNAUTHORIZED' })
  })

  it.each([
    { ...validBody, email: 'invalid' },
    { ...validBody, code: '12345' },
    { ...validBody, type: 'reset' },
    { ...validBody, accountId: 10 },
  ])('rejects invalid or over-specified payloads', async (payload) => {
    const config = testConfig()
    const server = buildServer(config, fakeMailer())
    servers.push(server)
    const response = await server.inject({
      method: 'POST',
      url: '/v1/email/verification',
      headers: { 'x-gcore-mail-token': config.token },
      payload,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toEqual({ ok: false, code: 'MAIL-INVALID-REQUEST' })
  })

  it('enforces an additional bounded local rate limit', async () => {
    const config = testConfig({ rateLimit: { windowMs: 60_000, maximum: 1 } })
    const server = buildServer(config, fakeMailer())
    servers.push(server)
    const request = {
      method: 'POST' as const,
      url: '/v1/email/verification',
      headers: { 'x-gcore-mail-token': config.token },
      payload: validBody,
    }
    expect((await server.inject(request)).statusCode).toBe(202)
    const rejected = await server.inject(request)
    expect(rejected.statusCode).toBe(429)
    expect(rejected.json()).toEqual({ ok: false, code: 'MAIL-RATE-LIMITED' })
  })

  it('rejects malformed JSON and oversized bodies with stable codes', async () => {
    const config = testConfig()
    const server = buildServer(config, fakeMailer())
    servers.push(server)
    const headers = {
      'content-type': 'application/json',
      'x-gcore-mail-token': config.token,
    }

    const malformed = await server.inject({
      method: 'POST', url: '/v1/email/verification', headers, payload: '{',
    })
    expect(malformed.statusCode).toBe(400)
    expect(malformed.json()).toEqual({ ok: false, code: 'MAIL-INVALID-REQUEST' })

    const oversized = await server.inject({
      method: 'POST',
      url: '/v1/email/verification',
      headers,
      payload: JSON.stringify({ ...validBody, padding: 'x'.repeat(9000) }),
    })
    expect(oversized.statusCode).toBe(413)
    expect(oversized.json()).toEqual({ ok: false, code: 'MAIL-BODY-TOO-LARGE' })
  })
})

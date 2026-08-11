import { afterEach, describe, expect, it } from 'vitest'
import { loadConfig } from '../src/config.js'
import { buildServer } from '../src/server.js'
import { fakeMailer, testConfig } from './helpers.js'

const servers: ReturnType<typeof buildServer>[] = []
afterEach(async () => Promise.all(servers.splice(0).map((server) => server.close())))

describe('mail service health and config', () => {
  it('returns a secret-free health response', async () => {
    const server = buildServer(testConfig(), fakeMailer())
    servers.push(server)
    const response = await server.inject({ method: 'GET', url: '/health' })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toEqual({
      ok: true,
      service: 'gcore-mail-service',
      status: 'healthy',
    })
    expect(response.body).not.toContain('test-token')
  })

  it('refuses every non-loopback bind address', () => {
    expect(() => loadConfig({
      MAIL_SERVICE_HOST: '0.0.0.0',
      MAIL_SERVICE_TOKEN: 'a'.repeat(32),
      SMTP_HOST: '127.0.0.1',
      MAIL_FROM_ADDRESS: 'no-reply@gcore.local',
    })).toThrow('MAIL-CONFIG-UNSAFE-HOST')
  })

  it('requires a long local token', () => {
    expect(() => loadConfig({
      MAIL_SERVICE_TOKEN: 'short',
      SMTP_HOST: '127.0.0.1',
      MAIL_FROM_ADDRESS: 'no-reply@gcore.local',
    })).toThrow('MAIL-CONFIG-WEAK-TOKEN')
  })
})

import { readFile } from 'node:fs/promises'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { renderVerification } from '../src/mailer.js'
import { buildServer } from '../src/server.js'
import type { VerificationRequest } from '../src/validation.js'
import { fakeMailer, testConfig } from './helpers.js'

const servers: ReturnType<typeof buildServer>[] = []
afterEach(async () => Promise.all(servers.splice(0).map((server) => server.close())))

describe('verification delivery', () => {
  it('accepts a valid request and delegates only presentation data', async () => {
    let delivered: VerificationRequest | undefined
    const config = testConfig()
    const server = buildServer(config, fakeMailer(async (request) => { delivered = request }))
    servers.push(server)
    const response = await server.inject({
      method: 'POST',
      url: '/v1/email/verification',
      headers: { 'x-gcore-mail-token': config.token },
      payload: { email: 'First.Last@Example.org', code: '483921', type: 'authentication' },
    })

    expect(response.statusCode).toBe(202)
    expect(response.json()).toEqual({ ok: true, status: 'sent' })
    expect(delivered).toEqual({
      email: 'first.last@example.org',
      code: '483921',
      type: 'authentication',
    })
  })

  it('maps SMTP failure to a stable secret-free response', async () => {
    vi.spyOn(process.stderr, 'write').mockImplementation(() => true)
    const config = testConfig()
    const server = buildServer(config, fakeMailer(async () => { throw new Error('credential secret') }))
    servers.push(server)
    const response = await server.inject({
      method: 'POST',
      url: '/v1/email/verification',
      headers: { 'x-gcore-mail-token': config.token },
      payload: { email: 'user@example.com', code: '000001', type: 'registration' },
    })
    expect(response.statusCode).toBe(502)
    expect(response.json()).toEqual({ ok: false, code: 'MAIL-SMTP-FAILED' })
    expect(response.body).not.toContain('credential secret')
  })

  it('renders both HTML and plain-text branded templates', async () => {
    const templateDirectory = testConfig().templatesDirectory
    const [html, text] = await Promise.all([
      readFile(`${templateDirectory}/verification.html`, 'utf8'),
      readFile(`${templateDirectory}/verification.txt`, 'utf8'),
    ])
    const request: VerificationRequest = {
      email: 'user@example.com', code: '483921', type: 'registration',
    }
    const renderedHtml = renderVerification(html, request)
    const renderedText = renderVerification(text, request)
    expect(renderedHtml).toContain('483921')
    expect(renderedHtml).toContain('Подтверждение регистрации')
    expect(renderedText).toContain('483921')
    expect(renderedText).not.toContain('{{')
  })
})

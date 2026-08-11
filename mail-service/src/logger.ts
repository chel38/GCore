export function maskEmail(email: string): string {
  const [local = '', domain = 'invalid'] = email.split('@', 2)
  return `${local.slice(0, 1) || '*'}***@${domain}`
}

export const logger = {
  info(message: string): void {
    process.stdout.write(`[GCore Mail][INFO] ${message}\n`)
  },
  warn(message: string): void {
    process.stderr.write(`[GCore Mail][WARN] ${message}\n`)
  },
  error(message: string): void {
    process.stderr.write(`[GCore Mail][ERROR] ${message}\n`)
  },
}

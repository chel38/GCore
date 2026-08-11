export class FixedWindowRateLimiter {
  private startedAt = 0
  private count = 0

  constructor(
    private readonly windowMs: number,
    private readonly maximum: number,
    private readonly now: () => number = Date.now,
  ) {}

  allow(): boolean {
    const current = this.now()
    if (current - this.startedAt >= this.windowMs) {
      this.startedAt = current
      this.count = 0
    }

    this.count += 1
    return this.count <= this.maximum
  }
}

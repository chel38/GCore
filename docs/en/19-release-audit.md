# 0.1.2-alpha release audit

Runtime detection, version separation, strict handshakes, server-authoritative
recovery/spawn verification, one-time decisions, bounded new-model retry, payload
schemas, rate-limit decay, API DTOs, isolated tests, CI, RU/EN documentation, and
txAdmin startup are complete.

The remaining manual boundary is an end-to-end connection from a real FiveM game
client, including live network ownership migration and coordinate replication.
That path fails closed and is bounded by retry and timeout.

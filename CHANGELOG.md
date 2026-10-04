# Changelog

## 1.0.1 — 2026-10-04

- Accept finite signed raw API scores; the backend uses an open-ended additive
  scale, so negative safe results and blocked scores over 100 are valid.
- Preserve strict status/envelope validation and reject nonnumeric/nonfinite scores.
- Add client and real moderation regressions; high-score blocked posts enter review.

## 1.0.0 — 2026-10-04

- Public new topic/reply checks using the canonical platform-key scan API.
- Human moderation through the native Discourse queue for blocked verdicts;
  optional review of suspicious verdicts and preservation of native approval rules.
- Disabled by default, server-only secret key, private/staff/trusted/import exclusions
  and optional author metadata disabled by default.
- Bounded TLS requests, strict verdict validation and API failure fallback.
- Real-core moderation/approval/privacy tests and release/main CI configuration.

Publication and completed verification evidence belong in PUBLICATION.md.

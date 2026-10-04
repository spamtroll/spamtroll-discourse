# Discourse plugin publication preparation

## Outcome

The public [source repository](https://github.com/spamtroll/spamtroll-discourse)
was created and its main branch verified on 4 October 2026. Public
[release v1.0.0](https://github.com/spamtroll/spamtroll-discourse/releases/tag/v1.0.0)
was uploaded from source commit 54a7c6e and re-fetched successfully. Both public
assets match the verified local archive and checksum; SHA256 is
`9689429ae0ea34329eeb918548598edf567fb1c7f036677ddd40275c06a9dd1f`.
GitHub [CI run 37214218032](https://github.com/spamtroll/spamtroll-discourse/actions/runs/37214218032)
passed both release/main jobs including package build. No Meta announcement has
been sent. A copy of this document inside an archive reflects its build-time checkpoint;
consult the current repository copy for subsequent publication evidence.

## Completed verification

| Discourse source | Core commit | Result |
| --- | --- | --- |
| v2026.9.0 | 343b20f9 | 41 examples, no failures; 8.37 seconds plus boot. |
| main, checked 4 October 2026 | 67bc74d0 | 41 examples, no failures; 8.33 seconds plus boot. |

Tests ran in native-arm64 `discourse/discourse_test:release`, image digest
`sha256:b61cd82e98a270c9927b1fe56e35042bfa1c17f30b2b3517d044b406625b9e25`,
with Ruby 3.4.11, PostgreSQL 18 and Redis. Suites exercise actual moderator queue and
approval, new topic/reply creation, native approval reasons, API errors/timeouts,
malformed/oversized responses, private/staff/trust exclusions, optional metadata and
server-only secret settings. API requests are offline stubs and no mail is sent.
Disposable test containers have been removed. Ruby/Bash/YAML syntax checks pass.

The official [Plugin category](https://meta.discourse.org/c/customization/plugin/22)
is the identified community publication destination. An authorized Meta account and
an explicit posting instruction are required. An announcement does not establish
official Discourse endorsement. Keep the actual post URL/version/date below once
published; do not fabricate a submission receipt.

## Reviewable announcement draft — not sent

**Title:** Spamtroll: spam checks with moderator approval for public Discourse posts

Spamtroll for Discourse checks eligible new public topics and replies with the
Spamtroll service. A blocked verdict goes to the normal moderator queue, where a
human can approve or reject the content. Suspicious verdicts can also be queued.
API failures continue through Discourse's native posting and moderation.

The plugin starts disabled. Staff, higher-trust users, private messages, restricted
categories and imported/reviewed posts are skipped. Default scans send public
content only; sending author email or last known IP is optional and starts disabled.
The platform API key stays on the server. Requests use TLS verification and a
five-second total deadline; malformed responses, quota/rate-limit errors and
unavailable API calls do not invent a clean verdict.

Plugin software is MIT licensed; the hosted service requires a Spamtroll account
and platform API key. Installation, limits and data flow are documented in README.

Verified with 41 passing tests on each of Discourse v2026.9.0 (343b20f9) and main
(67bc74d0), covering real moderator queue/approval and failure/privacy paths.
Source: https://github.com/spamtroll/spamtroll-discourse

Release: https://github.com/spamtroll/spamtroll-discourse/releases/tag/v1.0.0

Checksum: https://github.com/spamtroll/spamtroll-discourse/releases/download/v1.0.0/spamtroll-discourse-1.0.0.tar.gz.sha256

This is a third-party plugin, with no claimed official Discourse endorsement.

## Publication checklist

- [x] Actual supported-core verification and exact commits/results recorded.
- [x] Committed distribution includes license and matches version 1.0.0.
- [x] Public repository/release re-fetched and version/contents/checksum verified.
- [ ] Obtain explicit authorization and an accessible account/session for the Meta post.
- [ ] Record actual Meta post URL and publication outcome in canonical Spamtroll T-017.

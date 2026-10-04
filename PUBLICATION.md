# Discourse plugin publication preparation

## Outcome

The public source and original v1.0.0 release are available. A 1.0.1 patch
corrects the raw-score domain: blocked scores over 100 now enter human review
and negative scores remain valid. Source, CI and downloaded-asset evidence for
the patch will be recorded after verification and release.

The user instructed on 4 October 2026 to leave the Meta announcement as a ready
draft. No Meta announcement has been sent. A document inside an archive reflects
its build-time checkpoint; consult this repository copy for later release evidence.

## Completed verification

| Discourse source | Core commit | Result |
| --- | --- | --- |
| v2026.9.0 | 343b20f9 | 48 examples, no failures; 8.15 seconds plus boot. |
| main, checked 4 October 2026 | 67bc74d0 | 48 examples, no failures; 8.14 seconds plus boot. |

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

Verified with 48 passing tests on each of Discourse v2026.9.0 (343b20f9) and main
(67bc74d0), covering real moderator queue/approval and failure/privacy paths.
Source: https://github.com/spamtroll/spamtroll-discourse

Release: https://github.com/spamtroll/spamtroll-discourse/releases/tag/v1.0.1

Checksum: https://github.com/spamtroll/spamtroll-discourse/releases/download/v1.0.1/spamtroll-discourse-1.0.1.tar.gz.sha256

This is a third-party plugin, with no claimed official Discourse endorsement.

## Publication checklist

- [x] Actual supported-core verification and exact commits/results recorded.
- [x] Committed distribution includes license and matches version 1.0.1.
- [ ] Patch archive/release re-fetch and checksum verification pending publication.
- [x] User chose to retain the prepared Meta draft without sending (4 October 2026).
- [x] No Meta topic URL is claimed; sending is deferred by the user.

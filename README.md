# Spamtroll for Discourse

Scan eligible new public topics/replies with [Spamtroll](https://spamtroll.io).
Blocked verdicts enter Discourse's existing moderator approval queue. A moderator
can approve or reject them. Valid safe verdicts continue normally; suspicious
verdicts enter the queue only when configured. API failures continue through
native Discourse posting/moderation without inventing a safe verdict.

**Preparation status:** version 1.0.0 candidate, local implementation. Real-core
verification and publication outcome are recorded in `PUBLICATION.md`; do not
assume the planned GitHub URL or a Meta topic has been published.

## Compatibility and installation

Targets Discourse v2026.9.0 and later compatible releases. CI also tests current
main; compatibility is evidence for the tested commits, not a guarantee for every
future release. A hosting environment that allows third-party server plugins is
required, together with a Spamtroll account/platform API key.

After the repository is published, use the standard Discourse plugin installation
procedure in [the official guide](https://meta.discourse.org/t/install-a-plugin/19157),
then rebuild the application. The intended repository URL is
`https://github.com/spamtroll/spamtroll-discourse` (not yet verified as published).
For a local development/test installation, place this checkout in Discourse's
`plugins/spamtroll-discourse` directory or use the test harness below.

In administrator site settings, enter `spamtroll_api_key` and enable
`spamtroll_enabled`. The plugin defaults to disabled. Settings are server-only,
and the key is marked secret. Scan requests use the fixed HTTPS Spamtroll endpoint
and the `X-API-Key` header; redirects are not followed.

| Setting | Default | Behavior |
| --- | --- | --- |
| `spamtroll_max_trust_level` | 1 | Scan users at trust levels 0–1; staff always skipped. |
| `spamtroll_review_suspicious` | false | Also queue suspicious verdicts when enabled. |
| `spamtroll_send_author_email` | false | Include the author's email when enabled. |
| `spamtroll_send_author_ip` | false | Include the last known author IP, which may differ from the current request IP. |

Staff/trusted users, private messages, restricted categories, imported/reviewed
posts and explicit validation bypasses are skipped. Native approval policies keep
their existing reasons. The plugin does not scan edits, registrations or historical
posts, and does not delete posts, ban or silence users based on Spamtroll verdicts.

## Data and failure behavior

The default request sends public title/body content and source `comment` to the
hosted service. Author email/IP are optional and disabled by default; consider
these fields when updating the forum's privacy notice. The API sees the forum
server's connection IP even when author IP is omitted. Private messages and
restricted-category content are never submitted by this plugin.

Requests have a five-second total deadline, smaller connection/read/write limits,
no automatic retries and TLS certificate verification. Content over the API's
64 KiB limit is skipped; it is not partially classified. Responses are bounded to
64 KiB and require the canonical successful envelope, known status and numeric
0–100 score. Invalid responses, transport/TLS errors, timeout, authentication,
quota and rate-limit errors all return to native posting/moderation.

No API key, content, author identity, response body or remote error text is written
to plugin logs. Transport/parser errors log only the exception class. Queued content
uses Discourse's normal reviewable storage; the plugin stores no extra verdict text
or credentials there. Availability/accuracy/service pricing are not guaranteed by
the plugin's MIT license.

## Verification and package

`spec/lib/client_spec.rb` checks transport, bounds, strict envelopes and secret
handling. `spec/integration/post_gate_spec.rb` runs real Discourse creation,
moderation and approval with offline HTTP stubs; it never calls the live scan API.
CI uses Discourse's official test image with PostgreSQL/Redis and a release/main
matrix. `scripts/test_core.sh CORE_PATH PLUGIN_PATH` runs inside a disposable test
container/CI environment and must not be run against a production database.

After committing a verified candidate, `bash scripts/build.sh` archives the committed
runtime, settings, documentation and MIT notice into `dist/` with a SHA256 manifest.
Generated dependency checkouts, caches, tests and local credentials are excluded.

Support/reporting and release links become actionable when the repository is
published. See `PUBLICATION.md` for the reviewable announcement and actual outcome.

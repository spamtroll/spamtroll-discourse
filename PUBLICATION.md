# Discourse plugin publication preparation

## Outcome

As of 4 October 2026, this is a local version 1.0.0 candidate. No GitHub repository,
release or Meta announcement has been published by this task. Integration verification
is underway against Discourse v2026.9.0 and current main. Do not describe pending
checks as passing or the intended repository URL as an installed public release.

The official [Plugin category](https://meta.discourse.org/c/customization/plugin/22)
is the identified community publication destination. An authorized Meta account and
an explicit posting instruction are required. An announcement does not establish
official Discourse endorsement. Keep the actual post URL/version/date below once
published; do not fabricate a submission receipt.

## Reviewable announcement draft — update evidence before sending

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

Before posting, replace this sentence with the exact tested Discourse versions,
passing test counts and public repository/release/checksum links. Do not imply
hosted-service pricing, certification, official endorsement or publication that
has not been verified.

## Publication checklist

- Finish actual supported-core verification and record exact commits/results.
- Verify the committed distribution includes its license and matches version 1.0.0.
- Publish/re-fetch the intended repository and release artifacts through an authorized
  repository destination; verify links before inserting them in the announcement.
- Obtain explicit authorization/account context for the final Meta post.
- Record outcome, post URL and published version in canonical Spamtroll T-017.

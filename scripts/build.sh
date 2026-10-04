#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(sed -n 's/^# version: //p' plugin.rb)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
mkdir -p dist
artifact="spamtroll-discourse-${version}.tar.gz"
git archive --format=tar --prefix=spamtroll-discourse/ HEAD \
  plugin.rb lib config README.md LICENSE CHANGELOG.md PUBLICATION.md | gzip -n > "dist/$artifact"
(cd dist && shasum -a 256 "$artifact" > "$artifact.sha256")
printf '%s\n' "dist/$artifact"

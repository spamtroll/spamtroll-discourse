#!/usr/bin/env bash
# Run inside the official discourse/discourse_test image or equivalent disposable CI.
set -euo pipefail
core="$(cd "$1" && pwd)"
plugin="$(cd "${2:-$(dirname "$0")/..}" && pwd)"
test -f "$core/Gemfile"
test -f "$core/lib/new_post_manager.rb"
test -f "$plugin/plugin.rb"
cd "$core"
git config --global --add safe.directory "$core"
export RAILS_ENV=test PGUSER=discourse PGPASSWORD=discourse LOAD_PLUGINS=1
export RUBYOPT="${RUBYOPT:-} -W0"
redis-server /etc/redis/redis.conf --daemonize yes --logfile ""
install -d -o postgres -g postgres /var/run/postgresql
sudo -E -u postgres script/start_test_db.rb
sudo -u postgres psql -c "CREATE ROLE discourse LOGIN SUPERUSER PASSWORD 'discourse';"
if [[ ! -e plugins/spamtroll-discourse ]]; then
  ln -s "$plugin" plugins/spamtroll-discourse
fi
test "$(readlink plugins/spamtroll-discourse)" = "$plugin"
bundle config --local path /var/www/discourse/vendor/bundle
bundle config --local deployment true
bundle config --local without development
bundle install --jobs 4
pnpm install --frozen-lockfile
bundle exec rake db:create db:migrate
bundle exec rspec "$plugin/spec" --format documentation

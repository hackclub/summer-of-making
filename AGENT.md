# AGENT.md - Rails SOM Project

## Important: Always run formatting and linting after every code change
- Run `docker compose run web bundle exec rubocop -A` after any code modifications
- Run `docker compose run --no-deps web bundle exec erb_lint --lint-all --autocorrect` after ERB template changes

## Git Best Practices
- NEVER use `git add .` - Multiple agents may be running simultaneously
- Always add specific files you've modified: `git add path/to/specific/file`

## Docker Compose Tips
- Add `--remove-orphans` flag to docker compose commands to avoid orphan container warnings (e.g., `docker compose run --remove-orphans web rails test`)

## Commands (via Docker Compose)
- **Tests**: `rails test` (all), `docker compose run web rails test test/models/user_test.rb` (single file), `docker compose run web rails test test/models/user_test.rb -n test_method_name` (single test) - Note: Limited test coverage
- **Lint**: `docker compose run web bundle exec rubocop` (check), `docker compose run web bundle exec rubocop -A` (auto-fix)
- **ERB Lint**: `docker compose run --no-deps web bundle exec erb_lint --lint-all` (check), `docker compose run --no-deps web bundle exec erb_lint --lint-all --autocorrect` (auto-fix)
- **Console**: `docker compose run web rails c` (interactive console)
- **Server**: `docker compose run --service-ports web rails s -b 0.0.0.0` (development server)
- **Database**: `docker compose run web rails db:migrate`, `docker compose run web rails db:create`, `docker compose run web rails db:schema:load`, `docker compose run web rails db:seed`
- **Migrations**: `docker compose run web rails g migration MigrationName` (generate new migration with proper timestamp)
- **Security**: `docker compose run web bundle exec brakeman` (security audit)
- **JS Security**: `docker compose run web bin/importmap audit` (JS dependency scan)
- **Zeitwerk**: `docker compose run web bin/rails zeitwerk:check` (autoloader check)
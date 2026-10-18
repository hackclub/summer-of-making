# Gem upgrade review — 2026-10-18

Updated 30 direct dependencies and 33 transitive dependencies, and added the explicit `yaml` dependency pulled in by RDoc. All direct gems active on the locked platforms now match the latest stable RubyGems releases checked on this date; Rails was already current at 8.1.4. Ruby and Bundler remain 3.4.11 and 4.0.20.

`bundle outdated --parseable` reports only two transitive dependencies that cannot be upgraded independently:

| Gem | Resolved | Latest | Constraint |
| --- | --- | --- | --- |
| marcel | 1.2.1 | 2.1.0 | Active Storage 8.1.4 requires `~> 1.0` |
| redis-client | 0.30.1 | 0.31.0 | Redis 6.0.0 requires exactly `0.30.1` |

`tzinfo-data` is conditional on Windows/JRuby and is not resolved on the current macOS/Linux platforms; its Gemfile entry remains unconstrained.

Reviewed upstream changelogs/release notes for the changed dependencies and checked affected APIs against this checkout. Where a gem's packaged changelog redirects to GitHub releases, used those release notes instead. No prereleases included.

## Direct dependency review

| Gem | Before → After | Breaking changes / action |
| --- | --- | --- |
| [aasm](https://github.com/aasm/aasm/blob/master/CHANGELOG.md) | 5.5.2 → 6.0.0 | Persistence failures now raise by default. Set `whiny_persistence: false` on `ShopOrder` to retain its existing behavior; regression tested. |
| [annotaterb](https://github.com/drwl/annotaterb/blob/main/CHANGELOG.md) | 4.22.0 → 4.25.0 | Annotation fixes and new constraint support; both frozen annotation checks pass without regenerating files. |
| [avo](https://docs.avohq.io/4.0/avo-3-avo-4-upgrade.html) | 3.32.4 → 4.3.2 | See Avo audit below. Resource field definitions and CSS compilation pass; visual redesign needs signed-in review. |
| [aws-sdk-s3](https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-sdk-s3/CHANGELOG.md) | 1.233.1 → 1.233.2 | Transfer cleanup and exceptional-worker failure fixes; no call-site migration. |
| [bullet](https://github.com/flyerhzm/bullet/blob/main/CHANGELOG.md) | 8.1.1 → 8.3.0 | Drops Active Record < 7 / Mongoid < 8; this app uses Rails 8.1.4. |
| [connection_pool](https://github.com/mperham/connection_pool/blob/main/Changes.md) | 2.5.5 → 3.0.2 | Checkout/reap use keyword arguments. No direct calls to the changed methods in the app; current Rails and redis-client support 3.x. |
| [ferrum_pdf](https://github.com/excid3/ferrum_pdf/blob/main/CHANGELOG.md) | 0.3.0 → 3.2.0 | 2.x replaces controller PDF methods with renderers; 3.x removes `base_url` and inline asset helpers. None of these APIs is used in this checkout. |
| [flipper](https://github.com/flippercloud/flipper/releases/tag/v1.4.2) | 1.3.4 → 1.4.2 | Cloud/adapter fixes and additions. The app uses Active Record, not Cloud. |
| [flipper-active_record](https://github.com/flippercloud/flipper/releases/tag/v1.4.2) | 1.3.4 → 1.4.2 | Updated with the other Flipper gems; no schema migration required. |
| [flipper-active_support_cache_store](https://github.com/flippercloud/flipper/releases/tag/v1.4.2) | 1.3.4 → 1.4.2 | Replaced deprecated `expires_in:` with positional TTL, preserving five-minute expiry. |
| [flipper-ui](https://github.com/flippercloud/flipper/releases/tag/v1.4.2) | 1.3.4 → 1.4.2 | Updated with Flipper core; existing configuration boots. |
| [jbuilder](https://github.com/rails/jbuilder/releases/tag/v2.15.1) | 2.14.1 → 2.15.1 | `method_missing` is now private; partial-rendering fixes. No direct calls to that internal method. |
| [json](https://github.com/ruby/json/blob/master/CHANGES.md) | 2.21.2 → 3.1.0 | 3.x rejects duplicate keys/comments, removes `create_additions`, aliases and mutable defaults, and checks option names. App calls use standard APIs; no global permissive compatibility patch added. Non-ASCII binary generation also raises in 3.1. |
| [kamal](https://github.com/basecamp/kamal) | 2.11.0 → 2.12.0 | Deployment tooling fixes/options; no deployment performed. |
| [lz_string](https://github.com/altivi/lz_string/blob/master/CHANGELOG.md) | 0.3.0 → 1.0.0 | Raw compression returns UTF-16LE, binary input validation is stricter, and Unicode/emoji compatibility is fixed. App uses UTF16 output; tested Identity Vault encoding with Unicode. |
| [mission_control-jobs](https://github.com/rails/mission_control-jobs) | 1.1.0 → 1.3.1 | Batch/filtering/UI improvements and Propshaft fixes; existing base controller/auth configuration retained. |
| [pagy](https://ddnexus.github.io/pagy/changelog/) | 9.4.0 → 43.8.1 | Migrated controller mixin, initializer, navigation/info helpers and range errors. Changed pagination `items:` to `limit:`; preserved API response `items` keys and overflow 404s/redirects. |
| [pg](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md) | 1.6.3 → 1.7.0 | Drops Ruby < 3.1 and `static_symbol` field names; no app usage. Includes JSON 3 compatibility fixes. |
| [rack-mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler/blob/master/CHANGELOG.md) | 4.0.1 → 5.0.0 | Requires Ruby >= 3.2; advanced debug tools are disabled by default in development. Profiling authorization call remains supported. |
| [rbtrace](http://github.com/tmm1/rbtrace) | 0.5.3 → 0.5.5 | Native command validation and Ruby compatibility fixes; no call-site migration. |
| [redis](https://github.com/redis/redis-rb/blob/master/CHANGELOG.md) | 5.4.1 → 6.0.0 | RESP3 is now default; geographical coordinates become floats. No direct Redis commands/configuration in this app; Solid Cache/Queue/Cable are the active stores. |
| [ruby-lsp](https://github.com/Shopify/ruby-lsp) | 0.26.9 → 0.26.11 | Editor integration fixes; no app migration. |
| [selenium-webdriver](https://github.com/SeleniumHQ/selenium/blob/trunk/rb/CHANGES) | 4.44.0 → 4.51.0 | CDP updates; removes deprecated Firefox profile extension/certificate APIs. No app/system-test use of those APIs. |
| [slack-ruby-client](https://github.com/slack-ruby/slack-ruby-client/blob/master/CHANGELOG.md) | 3.1.0 → 3.3.0 | New API methods and bug fixes in 3.2/3.3; RTM removal was in the already-installed 3.0 line. No call-site migration. |
| [solid_cable](https://github.com/rails/solid_cable) | 3.0.12 → 4.1.0 | 4.x requires Ruby >= 3.3. Reconnect, message polling, batching, trimming and optional encryption changes; existing cable schema/configuration remains supported. |
| [solid_queue](https://github.com/rails/solid_queue) | 1.4.0 → 1.7.0 | Default polling interval changes to one second, but this app specifies all polling intervals. Batch schema additions are optional in 1.7; existing jobs work without them. Run `solid_queue:update` and migrate before adopting batches. |
| [strong_migrations](https://github.com/ankane/strong_migrations) | 2.7.0 → 2.8.0 | Adds a check for renaming enum values; no migrations changed. |
| [tailwindcss-rails](https://github.com/rails/tailwindcss-rails) | 4.4.0 → 4.6.0 | Watch process signal handling and silent mode; already on Tailwind 4, so no v3 migration needed. |
| [tailwindcss-ruby](https://github.com/flavorjones/tailwindcss-ruby/blob/main/CHANGELOG.md) | 4.3.0 → 4.3.3 | 4.3 patch updates; app and Avo CSS builds pass. |
| [thruster](https://github.com/basecamp/thruster) | 0.1.22 → 0.1.27 | Patch fixes; no app-specific migration identified. |

## Avo 3 → 4 audit

Compared the [upgrade guide](https://docs.avohq.io/4.0/avo-3-avo-4-upgrade.html) with the 12 resource definitions, generated Avo controllers, policies, and initializer. The Avo route mount is currently commented out; it remains disabled.

- **Layout/actions:** No active `main_panel`, custom panels/components, tabs, cluster/row layouts, action confirmations or custom controls to migrate. Resources use ordinary `field` declarations, supported by Avo's automatic field grouping.
- **Search/associations:** No active search definitions, searchable or nested association forms, custom picker CSS, scopes, or Pro/Advanced extensions. No new paid feature gems needed.
- **Appearance/icons/avatar/cover:** No active custom branding, icon, profile-photo, cover-photo or grid-badge declarations. Avo's built-in UI changes to the new design and Tabler icons.
- **Pagination:** No active Avo pagination customization. Avo 4 supports Pagy 43; migrated the host app's separate Pagy integration.
- **Authorization:** `authorization_client = nil` and `explicit_authorization = true` were already configured; retained them. The commented mount remains inside `AdminConstraint`; no Avo routes were enabled.
- **Breadcrumbs/fields/maps:** No active custom breadcrumbs, discreet DSL, label-help, map or field-wrapper customization to migrate.
- **Licensing/network:** No configured license key or WebMock/VCR network restriction. Avo 4's license behavior differs; signed-in licensed functionality has not been exercised.
- **Checks:** All 12 resource field definitions load, app eager loading passes, and Avo CSS compiles.

If Avo is re-enabled, manually verify signed-in navigation, association pages, and the redesigned UI/icons. Resource-definition and build checks do not establish browser-level parity.

## Transitive dependency review

| Gem | Before → After | Review |
| --- | --- | --- |
| [active_link_to](http://github.com/comfy/active_link_to) | 1.0.5 → 1.1.0 | Optional configuration; existing API retained. |
| [avo-icons](https://github.com/avo-hq/avo-icons/compare/v0.2.1...v0.2.3) | 0.2.1 → 0.2.3 | Icon refresh, SVG caching and fixes; reviewed commit comparison because no release notes were published. |
| [aws-partitions](https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-partitions/CHANGELOG.md) | 1.1293.0 → 1.1296.0 | AWS regions/endpoints data. |
| [date](https://github.com/ruby/date/releases) | 3.5.1 → 3.6.0 | Validation, encoding and performance fixes. |
| [et-orbi](https://github.com/floraison/et-orbi/blob/master/CHANGELOG.md) | 1.4.0 → 1.4.2 | UTC/time computation fixes. |
| [faraday](https://github.com/lostisland/faraday/releases/tag/v2.15.0) | 2.14.4 → 2.15.0 | Locks adapter changes after stack use; app configures adapters during connection creation. |
| [faraday-mashify](https://github.com/sue445/faraday-mashify/blob/v1.0.3/CHANGELOG.md) | 1.0.2 → 1.0.3 | Release tooling only. |
| [faraday-net_http](https://github.com/lostisland/faraday-net_http/releases/tag/v3.5.0) | 3.4.4 → 3.5.0 | Deflate errors now raise `Faraday::ConnectionFailed`; current retry handlers catch it. |
| [ferrum](https://github.com/rubycdp/ferrum/blob/main/CHANGELOG.md) | 0.17.2 → 0.19.1 | Same-origin security enabled by default in 0.19.1; stream/thread/connection fixes. No direct browser automation call sites. |
| [fugit](https://github.com/floraison/fugit/blob/master/CHANGELOG.md) | 1.12.1 → 1.14.0 | Inputs longer than 256 characters rejected; checked recurring schedules are shorter. |
| [language_server-protocol](https://github.com/mtsmfm/language_server-protocol-ruby) | 3.17.0.5 → 3.17.0.6 | LSP 3.17 regeneration; later prerelease breaking changes are outside this upgrade. |
| [listen](https://github.com/guard/listen/releases) | 3.10.0 → 3.10.1 | Filesystem watcher fixes. |
| [net-http](https://github.com/ruby/net-http/releases) | 0.9.1 → 0.10.0 | Stricter request/response header and Content-Length validation; no custom framing in app. |
| [net-imap](https://github.com/ruby/net-imap/releases) | 0.6.7 → 0.6.8 | Timeout mapping and SequenceSet fixes; no direct IMAP calls. |
| [net-smtp](https://github.com/ruby/net-smtp) | 0.5.1 → 0.5.2 | Session and SSL-context fixes. |
| [net-ssh](https://github.com/net-ssh/net-ssh/blob/master/CHANGES.txt) | 7.3.2 → 7.3.6 | SSH fixes; used by deployment tooling. |
| [parallel](https://github.com/grosser/parallel/blob/v2.3.0/CHANGELOG.md) | 2.1.0 → 2.3.0 | Worker/Ractor fixes and optional exit behavior; no direct Parallel calls. |
| [parser](https://github.com/whitequark/parser/blob/v3.3.12.0/CHANGELOG.md) | 3.3.11.1 → 3.3.12.0 | Ruby parser fixes. |
| [prettyprint](https://github.com/ruby/prettyprint) | 0.2.0 → 0.2.1 | API completion/documentation fixes. |
| [raabro](https://github.com/floraison/raabro/blob/master/CHANGELOG.md) | 1.4.0 → 1.5.0 | Parser hardening. |
| [rdoc](https://github.com/ruby/rdoc/releases) | 8.0.0 → 8.1.0 | JSON 3 support, parser fixes, and Darkfish deprecation; development documentation tooling. |
| [redis-client](https://github.com/redis-rb/redis-client/blob/master/CHANGELOG.md) | 0.29.0 → 0.30.1 | SSL/native build fixes; pinned by Redis 6.0.0. |
| [regexp_parser](https://github.com/ammar/regexp_parser/blob/master/CHANGELOG.md) | 2.12.0 → 2.13.1 | Input validation and match-length fixes. |
| [rubocop](https://github.com/rubocop/rubocop/releases/tag/v1.92.0) | 1.91.0 → 1.92.0 | New checks and bug fixes; full lint passes. |
| [rubocop-ast](https://github.com/rubocop/rubocop-ast/blob/master/CHANGELOG.md) | 1.49.1 → 1.50.0 | Parser/AST fixes and performance changes. |
| [rubocop-performance](https://github.com/rubocop/rubocop-performance/blob/master/CHANGELOG.md) | 1.26.1 → 1.27.0 | Requires RuboCop >= 1.89; resolved 1.92 satisfies it. |
| [rubocop-rails](https://github.com/rubocop/rubocop-rails/blob/master/CHANGELOG.md) | 2.35.0 → 2.38.0 | New checks and fixes; full lint passes. |
| [sshkit](https://github.com/capistrano/sshkit/releases) | 1.25.0 → 1.25.1 | Release housekeeping only. |
| [unicode-display_width](https://github.com/janlelis/unicode-display_width/blob/main/CHANGELOG.md) | 3.2.0 → 3.3.0 | Unicode 18 data and encoding fixes. |
| [unicode-emoji](https://github.com/janlelis/unicode-emoji) | 4.2.0 → 4.3.0 | Unicode/Emoji 18 data. |
| [uniform_notifier](https://github.com/flyerhzm/uniform_notifier/blob/master/CHANGELOG.md) | 1.18.0 → 1.18.1 | Packaging reduction only. |
| [uri](https://github.com/ruby/uri/releases) | 1.1.1 → 1.1.2 | Path merge correctness/performance. |
| [view_component](https://github.com/ViewComponent/view_component/blob/main/docs/CHANGELOG.md) | 4.15.0 → 4.16.0 | Collection/template/cache fixes; cache digest errors now propagate. |
| [yaml](https://github.com/ruby/yaml) | (new) → 0.4.0 | Newly explicit RDoc dependency; YAML::Store uses safe loading. No direct YAML::Store/PStore use. |

## Validation

All Rails/database commands used an isolated local PostgreSQL 16 container on `127.0.0.1:55447`, environment `test`, database `som_gems_test`. Verified environment and connected database before loading the schema. No production database, deployment, or external service operation was used.

Passed:

- Native macOS `bundle update` and Linux Docker Compose `bundle install`.
- Docker Compose RuboCop: **604 files, no offenses**; changed Ruby files also autocorrected/checked.
- Docker Compose ERB lint: **207 files, no errors**; changed templates also autocorrected/checked.
- Zeitwerk eager loading and Brakeman: **no security warnings**. Zeitwerk retains its existing note that `app/presenters` is not an eager-load path.
- App and Avo assets precompile with Tailwind 4.3.3.
- Frozen model and route annotation checks, with no annotation rewrites.
- All 12 Avo resource field definitions load.
- Focused dependency/media tests: **8 tests, 25 assertions, no failures/errors**. Covers API page slicing/response keys, overflow 404s, HTML navigation/info, failed order persistence, Unicode Identity Vault compression, and archived media behavior.
- `git diff --check`.

The full suite remains blocked by existing fixtures: **46 errors**, all referencing the missing `hcb_grant_shop_items` table. The original dependency bundle reproduces the same **49 tests, 13 assertions, 46 errors** against the same schema. The final upgraded suite adds five passing regression tests: **54 tests, 25 assertions, 46 errors, zero failures**. Fixture/schema repair is separate from this dependency upgrade.

Solid Queue's optional batch migration was not generated because this app does not use batches. Its README explicitly supports running 1.7 without that migration; adopting batches requires generating/reviewing and applying it first.

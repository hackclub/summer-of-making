# Privacy requests (GDPR deletion and export)

Deletion and export requests are run from the Hack Club privacy hub. The hub calls these endpoints once with `dry_run: true`. A human reviews the result, and after approval the hub calls again for real.

| Endpoint | Does |
| --- | --- |
| `POST /api/privacy/delete` | Deletes everything belonging to the subject (or reports it, on a dry run) |
| `POST /api/privacy/export` | Reports what is held. Export delivery isn't specified yet, so it never changes anything |

## Authentication

Each call carries `Authorization: Bearer <token>`: an ES256 JWT signed by the hub with a 5 minute lifetime. `Privacy::Token` verifies it against the hub's JWKS at `https://yeet.hackclub.com/.well-known/jwks.json` using Ruby's OpenSSL, with no extra gems.

The verifier checks:

- the signature and `kid`
- `typ: JWT`
- `iss` is `hackclub-privacy`
- `aud` is `summer-of-making`
- `exp` and `iat`, and that the lifetime is at most 300 seconds
- the shape of the claims

Keys are cached for 5 minutes and refetched when an unknown `kid` shows up, so key rotation on the hub needs no change here.

The endpoints act only on the token claims (`subject.emails`, `subject.slack_id`, `subject.identity_id`, `dry_run`), never the request body. A token's `jti` is accepted once: used IDs are recorded in `privacy_token_uses` and pruned after a day, far longer than a token can live.

Response: `200 {request_id, found, dry_run, deleted: {table: rows}, retained: [{type, count, reason}]}`. The endpoint is idempotent: once a user is deleted, later calls answer `found: false`.

Errors:

- `401 {error}` for a bad token
- `409` for a replayed token
- `400` when the token's action doesn't match the endpoint
- `503` when the JWKS can't be fetched (the hub retries)

## What gets deleted

`Privacy::Eraser` matches users by `lower(email)`, `slack_id`, or `identity_vault_id`, then deletes the user row. Foreign keys do the rest (`CascadeUserDeletion`):

- **Deleted with the user:** their profile, projects, devlogs, comments, likes, follows, stonks, timer sessions, badges, Hackatime data, vote queue, tutorial progress, magic links, and view events.
- **Deleted with their projects:** devlogs (including collaborators'), comments, likes, follows, ship events and feedback, certifications, README checks, vote changes, and other people's votes involving the project. Other projects' ratings are not recalculated.
- **Cleaned up by hand (no foreign key):**
  - attachments, whose blobs are purged after commit
  - paper_trail versions; `whodunnit` is cleared elsewhere
  - public_activity rows
  - Airtable sync rows
  - polymorphic likes and views of deleted records
  - legacy ahoy visits and events
  - email signups matching the email or Slack ID
- **Counter caches:** other people's `likes_count`, `comments_count`, `followers_count`, `votes_count`, and `devlogs_count` are recounted in the same transaction.

Kept, but detached from the account (`ON DELETE SET NULL`), and reported as `retained` with a reason:

| Kept | Why |
| --- | --- |
| Shop orders, warehouse packages, card grants | Accounting, fulfilment, customs |
| Payouts, reviewer payout requests | The currency ledger must balance |
| Fraud reports | Fraud prevention |
| Votes cast | Other projects' rankings. IP and user agent are cleared |
| Review decisions (certifications, YSWS reviews) | Integrity of other people's projects |

Open work is closed first, so nothing ships to or pays out to an account that no longer exists:

- Orders that are `pending`, `awaiting_periodical_fulfillment`, `in_verification_limbo`, or `on_hold` become `rejected`, with the reason "Cancelled: account deleted after a privacy request". No refund payout is made because the balance goes with the account.
- Pending reviewer payout requests become `rejected`.

Both are reported in `retained` as well.

### Detached records in the app

These associations are now `optional: true`, with presence still validated on create, so existing rows can lose their user while new ones still need one:

- `ShopOrder#user`, `Shop::WarehousePackage#user`, `ShopCardGrant#user`, `Payout#user`
- `FraudReport#reporter`, `Vote#user`, `VoteMf#voter`
- `YswsReview::DevlogApproval#user`, `ShipReviewerPayoutRequest#reviewer`

Admin pages show "Deleted user" for them. Approving, fulfilling, or converting a detached order to a preauth grant is refused, and so is approving a detached payout request; both can still be rejected. `/api/v2/payouts` returns `user: null` for detached payouts.

Data that lives outside this database is handled by the hub's own targets: Airtable copies, Slack, Hackatime, Loops, and Hack Club Auth. Airtable copies are reported as `retained` so reviewers see them.

## Dry runs

A dry run performs the real deletion inside a transaction. It reads the per-table delete counts Postgres tracks for that transaction (`pg_stat_xact_user_tables`, which includes cascaded deletes) and rolls back. Dry run and real run share one code path, so the reviewed numbers are the executed numbers.

## Running it against a local hub

Nothing needs configuring in production. To test against a hub running on your machine, override the JWKS URL:

```sh
# .env, or the web service's environment in docker compose
PRIVACY_JWKS_URL=http://host.docker.internal:44100/.well-known/jwks.json
```

In the hub, register a target with slug and audience `summer-of-making` and base URL `http://127.0.0.1:3000`.

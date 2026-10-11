module Privacy
  # Finds everyone matching a privacy subject and deletes their data. Deleting the user row
  # cascades through the foreign keys (see CascadeUserDeletion); this class handles the rest
  # (polymorphic and unconstrained references, other people's counter caches) and reports
  # what happened.
  #
  # A dry run performs the same deletion inside a transaction, reads the per-table delete
  # counts postgres tracks for that transaction, then rolls back, so dry run and real run
  # report the same numbers. Those counters also carry earlier transactions on the same
  # connection until postgres flushes them (never mid-transaction), so we diff a snapshot.
  class Eraser
    Result = Data.define(:found, :deleted, :retained)

    DETACHED = "detached from the account"
    REVIEW = "kept for the integrity of other people's projects; reviewer removed"

    RETAINED = [
      [ -> { ShopOrder.unscoped }, :user_id, "shop orders", "kept for accounting and fulfilment; #{DETACHED}" ],
      [ -> { Shop::WarehousePackage.unscoped }, :user_id, "shipped packages", "kept for customs and carrier claims; #{DETACHED}" ],
      [ -> { ShopCardGrant.unscoped }, :user_id, "card grants", "financial records kept for HCB accounting; #{DETACHED}" ],
      [ -> { Payout.unscoped }, :user_id, "currency ledger entries", "kept so balances stay correct; #{DETACHED}" ],
      [ -> { ShipReviewerPayoutRequest.unscoped }, :reviewer_id, "reviewer payout requests", "financial records kept for accounting; #{DETACHED}" ],
      [ -> { FraudReport.unscoped }, :user_id, "fraud reports", "kept for fraud prevention; #{DETACHED}" ],
      [ -> { Vote.unscoped }, :user_id, "votes cast", "kept so other projects' rankings stay stable; voter, IP and user agent removed" ],
      [ -> { ShipCertification.unscoped }, :reviewer_id, "review decisions", REVIEW ],
      [ -> { ReadmeCertification.unscoped }, :reviewer_id, "review decisions", REVIEW ],
      [ -> { YswsReview::Submission.unscoped }, :reviewer_id, "review decisions", REVIEW ],
      [ -> { YswsReview::DevlogApproval.unscoped }, :user_id, "review decisions", REVIEW ]
    ].freeze

    OPEN_ORDER_STATES = %w[pending awaiting_periodical_fulfillment in_verification_limbo on_hold].freeze
    CANCELLATION_NOTE = "Cancelled: account deleted after a privacy request"

    # open work for the account is closed before the account goes, so nothing ships or pays out to nobody
    CLOSED = [
      [ -> { ShopOrder.unscoped.where(aasm_state: OPEN_ORDER_STATES) }, :user_id, "cancelled shop orders", "unfulfilled orders are rejected so nothing ships to a deleted account" ],
      [ -> { ShipReviewerPayoutRequest.unscoped.pending }, :reviewer_id, "rejected reviewer payout requests", "pending requests are rejected since there is no account left to pay" ]
    ].freeze

    AIRTABLE_REASON = "copies synced to Airtable are not touched here; the privacy hub's Airtable target deletes them".freeze

    def initialize(subject)
      @subject = subject
    end

    def call(dry_run:)
      user_ids = matching_user_ids
      return Result.new(found: false, deleted: {}, retained: []) if user_ids.empty?

      retained = retained_counts(user_ids)
      deleted = {}
      blob_ids = []
      ActiveRecord::Base.transaction do
        before = delete_counters
        blob_ids = erase!(user_ids)
        deleted = delete_counters.filter_map { |table, count| [ table, count - before.fetch(table, 0) ] if count > before.fetch(table, 0) }.to_h
        raise ActiveRecord::Rollback if dry_run
      end
      ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge_later) unless dry_run

      Result.new(found: true, deleted:, retained:)
    end

    private

    def matching_user_ids
      scope = User.unscoped.none
      scope = scope.or(User.unscoped.where("lower(email) IN (?)", @subject.emails)) if @subject.emails.any?
      scope = scope.or(User.unscoped.where(slack_id: @subject.slack_id)) if @subject.slack_id
      scope = scope.or(User.unscoped.where(identity_vault_id: @subject.identity_id)) if @subject.identity_id
      scope.pluck(:id)
    end

    def retained_counts(user_ids)
      counts = Hash.new(0)
      reasons = {}
      (CLOSED + RETAINED).each do |scope, column, type, reason|
        count = scope.call.where(column => user_ids).count
        next if count.zero?

        counts[type] += count
        reasons[type] = reason
      end
      synced = AirtableSync.where(syncable_type: "User", syncable_id: user_ids).count
      if synced.positive?
        counts["airtable copies"] = synced
        reasons["airtable copies"] = AIRTABLE_REASON
      end
      counts.map { |type, count| { type:, count:, reason: reasons[type] } }
    end

    def erase!(user_ids)
      project_ids = Project.unscoped.where(user_id: user_ids).pluck(:id)
      devlog_ids = Devlog.unscoped.where(user_id: user_ids).or(Devlog.unscoped.where(project_id: project_ids)).pluck(:id)
      ship_event_ids = ShipEvent.unscoped.where(project_id: project_ids).pluck(:id)
      feedback_ids = ShipEventFeedback.unscoped.where(ship_event_id: ship_event_ids).pluck(:id)
      certification_ids = ShipCertification.unscoped.where(project_id: project_ids).pluck(:id)
      profile_ids = User::Profile.unscoped.where(user_id: user_ids).pluck(:id)
      users = User.unscoped.where(id: user_ids)
      emails = (@subject.emails + users.pluck(:email).compact.map(&:downcase)).uniq
      slack_ids = ([ @subject.slack_id ] + users.pluck(:slack_id)).compact.uniq
      counters = affected_counters(user_ids, project_ids, devlog_ids)

      records = {
        "User" => user_ids, "User::Profile" => profile_ids, "Project" => project_ids, "Devlog" => devlog_ids,
        "ShipEvent" => ship_event_ids, "ShipEventFeedback" => feedback_ids, "ShipCertification" => certification_ids
      }

      attachments = ActiveStorage::Attachment.none
      records.each { |type, ids| attachments = attachments.or(ActiveStorage::Attachment.where(record_type: type, record_id: ids)) }
      blob_ids = attachments.pluck(:blob_id)
      attachments.delete_all

      records.each do |type, ids|
        next if ids.empty?

        execute([ "DELETE FROM versions WHERE item_type = ? AND item_id IN (?)", type, ids ])
        execute([ "DELETE FROM activities WHERE trackable_type = ? AND trackable_id IN (?)", type, ids ])
        execute([ "DELETE FROM airtable_syncs WHERE syncable_type = ? AND syncable_id IN (?)", type, ids ])
        execute([ "DELETE FROM likes WHERE likeable_type = ? AND likeable_id IN (?)", type, ids ])
        execute([ "DELETE FROM view_events WHERE viewable_type = ? AND viewable_id IN (?)", type, ids ])
      end
      execute([ "UPDATE versions SET whodunnit = NULL WHERE whodunnit IN (?)", user_ids.map(&:to_s) ])
      execute([ "DELETE FROM activities WHERE (owner_type = 'User' AND owner_id IN (?)) OR (recipient_type = 'User' AND recipient_id IN (?))", user_ids, user_ids ])
      execute([ "DELETE FROM ahoy_events WHERE user_id IN (?)", user_ids ])
      execute([ "DELETE FROM ahoy_visits WHERE user_id IN (?)", user_ids ])
      execute([ "DELETE FROM email_signups WHERE lower(email) IN (?) OR slack_id IN (?)", emails.presence || [ "" ], slack_ids.presence || [ "" ] ])
      execute([ <<~SQL, CANCELLATION_NOTE, user_ids, OPEN_ORDER_STATES ])
        UPDATE shop_orders SET aasm_state = 'rejected', rejection_reason = ?, rejected_at = now()
        WHERE user_id IN (?) AND aasm_state IN (?)
      SQL
      execute([ "UPDATE ship_reviewer_payout_requests SET status = ? WHERE reviewer_id IN (?) AND status = ?",
        ShipReviewerPayoutRequest.statuses[:rejected], user_ids, ShipReviewerPayoutRequest.statuses[:pending] ])
      execute([ "UPDATE votes SET ip = NULL, user_agent = NULL WHERE user_id IN (?)", user_ids ])
      execute([ "UPDATE payouts SET user_id = NULL WHERE user_id IN (?)", user_ids ])
      execute([ "DELETE FROM users WHERE id IN (?)", user_ids ])

      recount!(counters)
      blob_ids
    end

    # other people's rows whose counter caches include rows the cascade is about to delete
    def affected_counters(user_ids, project_ids, devlog_ids)
      {
        devlogs: (Like.where(user_id: user_ids, likeable_type: "Devlog").pluck(:likeable_id) +
          Comment.where(user_id: user_ids).pluck(:devlog_id)).uniq - devlog_ids,
        projects: ProjectFollow.where(user_id: user_ids).pluck(:project_id).uniq - project_ids,
        users: (Vote.unscoped.where(project_1_id: project_ids).or(Vote.unscoped.where(project_2_id: project_ids)).pluck(:user_id) +
          Devlog.unscoped.where(project_id: project_ids).pluck(:user_id)).compact.uniq - user_ids
      }
    end

    def recount!(counters)
      if counters[:devlogs].any?
        execute([ <<~SQL, counters[:devlogs] ])
          UPDATE devlogs SET
            likes_count = (SELECT count(*) FROM likes WHERE likes.likeable_type = 'Devlog' AND likes.likeable_id = devlogs.id),
            comments_count = (SELECT count(*) FROM comments WHERE comments.devlog_id = devlogs.id)
          WHERE id IN (?)
        SQL
      end
      if counters[:projects].any?
        execute([ <<~SQL, counters[:projects] ])
          UPDATE projects SET followers_count = (SELECT count(*) FROM project_follows WHERE project_follows.project_id = projects.id)
          WHERE id IN (?)
        SQL
      end
      if counters[:users].any?
        execute([ <<~SQL, counters[:users] ])
          UPDATE users SET
            votes_count = (SELECT count(*) FROM votes WHERE votes.user_id = users.id),
            devlogs_count = (SELECT count(*) FROM devlogs WHERE devlogs.user_id = users.id)
          WHERE id IN (?)
        SQL
      end
    end

    def delete_counters
      rows = ActiveRecord::Base.connection.select_rows(<<~SQL)
        SELECT relname, n_tup_del FROM pg_stat_xact_user_tables
        WHERE n_tup_del > 0 AND relname NOT LIKE 'solid_%' ORDER BY relname
      SQL
      rows.to_h { |table, count| [ table, count.to_i ] }
    end

    def execute(statement)
      ActiveRecord::Base.connection.exec_update(ActiveRecord::Base.sanitize_sql(statement))
    end
  end
end

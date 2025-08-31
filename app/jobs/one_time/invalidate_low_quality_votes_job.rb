require "digest"
class OneTime::InvalidateLowQualityVotesJob < ApplicationJob
  queue_as :default
  # marked_by_user_id – set this to your SoM user ID
  def perform(marked_by_user_id: nil, dry_run: false)
    marked_by_user_id = marked_by_user_id.presence
    now_timestamp = Time.current

    total_fast_scope = Vote.where(status: "active").where("time_spent_voting_ms <= 30000")
    total_fast_count = total_fast_scope.count
    Rails.logger.info "Found #{total_fast_count} fast votes (<= 30s)"

    invalidated_fast = 0
    if total_fast_count > 0
      if dry_run
        Rails.logger.info "[dry-run] Would invalidate #{total_fast_count} fast votes"
      else
        total_fast_scope.in_batches(of: 1_000) do |batch|
          updates = {
            status: "invalid",
            invalid_reason: "too_fast_under_30s",
            marked_invalid_at: now_timestamp,
            marked_invalid_by_id: marked_by_user_id
          }
          updates[:is_low_quality] = true
          affected = batch.update_all(updates)
          invalidated_fast += affected
        end
        Rails.logger.info "Invalidated #{invalidated_fast} fast votes"
      end
    end

    # Per-user duplicate explanations: keep the earliest, invalidate the rest
    dup_groups = Vote.where(status: "active")
                     .group(:user_id, :explanation)
                     .having("COUNT(*) > 1")
                     .count

    invalidated_dups = 0
    if dup_groups.any?
      dup_groups.each do |(user_id, explanation), _count|
        votes_for_group = Vote.where(status: "active", user_id: user_id, explanation: explanation)
                               .order(:created_at)

        # we're leaving the earliest vote as-is aka keeper
        keeper = votes_for_group.first
        next_ids = votes_for_group.where.not(id: keeper.id).pluck(:id)
        next if next_ids.empty?

        if dry_run
          invalidated_dups += next_ids.length
        else
          updates = {
            status: "invalid",
            invalid_reason: "duplicate_explanation_for_user",
            marked_invalid_at: now_timestamp,
            marked_invalid_by_id: marked_by_user_id
          }
          updates[:is_low_quality] = true
          affected = Vote.where(id: next_ids).update_all(updates)
          invalidated_dups += affected
        end
      end
      Rails.logger.info "Invalidated #{invalidated_dups} duplicate explanation votes"
    end

    Rails.logger.info "Low-quality votes invalidation complete. Summary: fast=#{invalidated_fast}/#{total_fast_count}, per_user_duplicates=#{invalidated_dups}/#{dup_groups.values.sum}"
  end
end

class ActiveStorageMoveJob < ApplicationJob
    queue_as :default

    # a bit safer + it'll DM @cskartikey!
    def perform(source = "cloudflare", destination = "cloudflare_new", notify_user_id = 4)
        destination_service = ActiveStorage::Blob.services.fetch(destination.to_sym)

        notify_slack_id = User.find_by(id: notify_user_id)&.slack_id

        scope = ActiveStorage::Blob.where(service_name: source)
        total_to_process = scope.count
        migrated_count = 0

        scope.in_batches(of: 1000) do |relation|
            relation.each do |blob|
                begin
                    unless destination_service.exist?(blob.key)
                        blob.open do |file|
                            destination_service.upload(
                                blob.key,
                                file,
                                checksum: blob.checksum,
                                content_type: blob.content_type
                            )
                        end
                    end

                    unless destination_service.exist?(blob.key)
                        raise "Destination missing object after upload: #{blob.key}"
                    end

                    blob.update_columns(service_name: destination)
                    migrated_count += 1

                    if notify_slack_id.present? && (migrated_count % 1000 == 0)
                        SendSlackDmJob.perform_later(
                            notify_slack_id,
                            "Active Storage migration: migrated #{migrated_count}/#{total_to_process} blobs to #{destination}."
                        )
                    end
                rescue => e
                    Honeybadger.notify(e, context: { blob_id: blob.id, key: blob.key, source: source, destination: destination })
                    next
                end
            end
        end

        if notify_slack_id.present?
            SendSlackDmJob.perform_later(
                notify_slack_id,
                "Active Storage migration complete: migrated #{migrated_count}/#{total_to_process} blobs to #{destination}."
            )
        end
    end
end

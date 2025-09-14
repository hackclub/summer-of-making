class ActiveStorageMoveJob < ApplicationJob
    queue_as :default

    # a bit safer + it'll DM @cskartikey!
    def perform(source = "cloudflare", destination = "cloudflare_new", notify_user_id = 4)
        destination_service = ActiveStorage::Blob.services.fetch(destination.to_sym)

        notify_slack_id = User.find_by(id: notify_user_id)&.slack_id

        scope = ActiveStorage::Blob.where(service_name: source)
        batch_size = Integer(ENV.fetch("AS_MOVE_BATCH", 1000)) rescue 1000
        configured_concurrency = Integer(ENV.fetch("AS_MOVE_CONCURRENCY", 8)) rescue 8
        notify_every = Integer(ENV.fetch("AS_MOVE_NOTIFY_EVERY", 1000)) rescue 1000
        pool_size = (ActiveRecord::Base.connection_pool.size rescue 5)
        max_concurrency = [ configured_concurrency, [ pool_size - 1, 1 ].max ].min
        concurrency = [ [ max_concurrency, 1 ].max, 64 ].min
        total_to_process = scope.count
        migrated_count = 0

        migrated_mutex = Mutex.new
        scope.in_batches(of: batch_size) do |relation|
            threads = []
            relation.each do |blob|
                threads << Thread.new do
                    ActiveRecord::Base.connection_pool.with_connection do
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

                            new_count = nil
                            migrated_mutex.synchronize do
                                migrated_count += 1
                                new_count = migrated_count
                            end

                            if notify_slack_id.present? && (new_count % notify_every == 0)
                                SendSlackDmJob.perform_later(
                                    notify_slack_id,
                                    "Active Storage migration: migrated #{new_count}/#{total_to_process} blobs to #{destination}."
                                )
                            end
                        rescue => e
                            Honeybadger.notify(e, context: { blob_id: blob.id, key: blob.key, source: source, destination: destination })
                        end
                    end
                end

                if threads.size >= concurrency
                    threads.shift.join
                end
            end

            threads.each(&:join)
        end

        if notify_slack_id.present?
            SendSlackDmJob.perform_later(
                notify_slack_id,
                "Active Storage migration complete: migrated #{migrated_count}/#{total_to_process} blobs to #{destination}."
            )
        end
    end
end

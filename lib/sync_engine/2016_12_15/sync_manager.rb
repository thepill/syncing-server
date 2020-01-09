module SyncEngine
  module V20161215
    class SyncManager < SyncEngine::AbstractSyncManager
      def sync(item_hashes, options, request)
        in_sync_token = options[:sync_token]
        in_cursor_token = options[:cursor_token]
        limit = options[:limit]
        content_type = options[:content_type] # optional, only return items of these type if present

        retrieved_items, cursor_token = _sync_get(in_sync_token, in_cursor_token, limit, content_type).to_a
        last_updated = DateTime.now
        saved_items, unsaved_items = _sync_save(item_hashes, request)

        unless saved_items.blank?
          last_updated = saved_items.max_by { |m| m.updated_at }.updated_at
        end

        check_for_conflicts(saved_items, retrieved_items, unsaved_items)

        # add 1 microsecond to avoid returning same object in subsequent sync
        last_updated = (last_updated.to_time + 1 / 100_000.0).to_datetime.utc

        sync_token = sync_token_from_datetime(last_updated)
        {
          retrieved_items: retrieved_items,
          saved_items: saved_items,
          unsaved: unsaved_items,
          sync_token: sync_token,
          cursor_token: cursor_token,
        }
      end

      def check_for_conflicts(saved_items, retrieved_items, unsaved_items)
        # conflicts occur when you are trying to save an item for which there is a pending change already
        min_conflict_interval = 20

        min_conflict_interval = 1 if Rails.env.development?

        saved_ids = saved_items.map { |x| x.uuid }
        retrieved_ids = retrieved_items.map { |x| x.uuid }
        conflicts = saved_ids & retrieved_ids # & is the intersection
        # saved items take precedence, retrieved items are duplicated with a new uuid
        conflicts.each do |conflicted_uuid|
          # if changes are greater than min_conflict_interval seconds apart,
          # push the retrieved item in the unsaved array so that the client can duplicate it
          saved = saved_items.find { |i| i.uuid == conflicted_uuid }
          conflicted = retrieved_items.find { |i| i.uuid == conflicted_uuid }

          if (saved.updated_at - conflicted.updated_at).abs > min_conflict_interval
            unsaved_items.push(
              item: conflicted,
              error: { tag: 'sync_conflict' }
            )
          end

          # We remove the item from retrieved items whether or not it satisfies the min_conflict_interval
          # This is because the 'saved' value takes precedence, since that's the current value in the database.
          # So by removing it from retrieved, we are forcing the client to ignore this change.
          retrieved_items.delete(conflicted)
        end
      end

      private

      def _sync_save(item_hashes, request)
        return [], [] unless item_hashes

        saved_items = []
        unsaved = []

        item_hashes.each do |item_hash|
          begin
            item = @user.items.find_or_create_by(uuid: item_hash[:uuid])
          rescue StandardError => e
            unsaved.push(
              item: item_hash,
              error: { message: e.message, tag: 'uuid_conflict' }
            )
            next
          end

          item.last_user_agent = request.user_agent
          item.update(item_hash.permit(*permitted_params))

          if item.deleted == true
            set_deleted(item)
            item.save
          end

          saved_items.push(item)
        end

        [saved_items, unsaved]
      end

      def _sync_get(sync_token, input_cursor_token, limit, content_type)
        cursor_token = nil
        limit = 100_000 if limit.nil?

        # if both are present, cursor_token takes precendence as that would eventually return all results
        # the distinction between getting results for a cursor and a sync token is that cursor results use a
        # >= comparison, while a sync token uses a > comparison. The reason for this is that cursor tokens are
        # typically used for initial syncs or imports, where a bunch of notes could have the exact same updated_at
        # by using >=, we don't miss those results on a subsequent call with a cursor token
        if input_cursor_token
          date = datetime_from_sync_token(input_cursor_token)
          items = @user.items.order(:updated_at).where('updated_at >= ?', date)
        elsif sync_token
          date = datetime_from_sync_token(sync_token)
          items = @user.items.order(:updated_at).where('updated_at > ?', date)
        else
          # if no cursor token and no sync token, this is an initial sync. No need to return deleted items.
          items = @user.items.order(:updated_at).where(deleted: false)
        end

        items = items.where(content_type: content_type) if content_type

        items = items.sort_by { |m| m.updated_at }

        if items.count > limit
          items = items.slice(0, limit)
          date = items.last.updated_at
          cursor_token = sync_token_from_datetime(date)
        end

        [items, cursor_token]
      end
    end
  end
end

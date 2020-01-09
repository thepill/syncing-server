class Item < ApplicationRecord
  belongs_to :user, foreign_key: 'user_uuid', optional: true

  def serializable_hash(options = {})
    super(options.merge(only: %w[uuid enc_item_key content content_type auth_hash deleted created_at updated_at]))
  end

  def decoded_content
    return nil if content.nil?

    begin
      string = content[3..content.length]
      decoded = Base64.decode64(string)
      JSON.parse(decoded)
    rescue StandardError
      nil
    end
  end

  def mark_as_deleted
    self.deleted = true
    self.content = nil if has_attribute?(:content)
    self.enc_item_key = nil if has_attribute?(:enc_item_key)
    self.auth_hash = nil if has_attribute?(:auth_hash)
    save
  end

  def daily_backup_extension?
    return false if content_type != 'SF|Extension'

    content = decoded_content
    content && content['frequency'] == 'daily'
  end

  def perform_associated_job
    content = decoded_content
    return unless content

    if content['subtype'] == 'backup.email_archive'
      # email job
      ArchiveMailer.data_backup(user_uuid).deliver_later
    elsif content['frequency'] == 'daily'
      # backup job
      return unless content['url']

      ExtensionJob.perform_later(url: content['url'], user_id: user_uuid, extension_id: uuid)
    end
  end
end

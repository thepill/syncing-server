class ExtensionJob < ApplicationJob
  require 'net/http'
  require 'uri'

  def perform(params)
    user = User.find_by_uuid(params[:user_id])
    return if user.nil?

    unless params[:auth_params_op]
      items = if params[:item_ids]
        user.items.find(params[:item_ids])
      else
        user.items.where(deleted: false).to_a
      end
    end

    auth_params = user.auth_params

    begin
      url = params[:url]
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      req.body = { items: items, auth_params: auth_params }.to_json
      http.use_ssl = (uri.scheme == 'https')
    rescue StandardError
      puts "Error creating ExtensionJob request with params #{params}."
      return
    end

    response = http.request(req)

    unless response.code.starts_with?('2')
      extension_id = params[:extension_id]
      settings = ExtensionSetting.find_or_create_by(extension_id: extension_id)
      return if settings.mute_emails

      # Dont send emails for realtime backups, only daily
      ext = Item.find(extension_id)
      content = ext.decoded_content
      return if !content || content['frequency'] == 'realtime'

      puts "Failed to execute extensions_job: #{response.to_json}"
      UserMailer.failed_backup(params[:user_id], extension_id, settings.uuid).deliver_later
    end
  end
end

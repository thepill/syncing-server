class MakeExtsDaily < ActiveRecord::Migration[5.0]
  def change
    extensions = Item.where(content_type: 'SF|Extension')
    extensions.each do |ext|
      unless ext.content
        next
      end
      string = ext.content[3..ext.content.length]
      decoded = Base64.decode64(string)
      obj = JSON.parse(decoded)
      url = obj['url']

      next unless ['dropbox', 'gdrive', 'onedrive', 'backup.email_archive'].include?(url)

      obj['frequency'] = 'daily'
      new_string = '000' + Base64.encode64(obj.to_json)
      ext.content = new_string
      ext.save
    end
  end
end

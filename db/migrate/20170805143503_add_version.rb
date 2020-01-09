class AddVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :version, :string

    User.transaction do
      User.all.each do |user|
        user.version = if user.pw_auth
          '002'
        else
          '001'
        end
        user.save
      end
    end
  end
end

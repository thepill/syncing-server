require 'rails_helper'

RSpec.describe User, type: :model do
  context 'with a single user' do
    it 'orders items chronologically' do
      u = User.create!
      item1 = u.items.create!
      sleep(1)
      item2 = u.items.create!
      expect(u.reload.items).to eq([item2, item1])
    end
  end
end

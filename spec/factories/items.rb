def encode_content(content)
  "---#{Base64.encode64(JSON.dump(content))}"
end

FactoryBot.define do
  factory :item do
    trait :extension_type do
      content_type { 'SF|Extension' }
    end

    trait :note_type do
      content_type { 'Note' }
    end

    trait :mfa_type do
      content { encode_content(secret: 'base32secretkey3232') }
      content_type { 'SF|MFA' }
    end

    trait :backup_daily do
      content { encode_content(frequency: 'daily', url: 'http://test.com') }
      content_type { 'SF|Extension' }
    end

    trait :backup_realtime do
      content { encode_content(frequency: 'realtime', url: 'http://test.com') }
      content_type { 'SF|Extension' }
    end
  end
end
# frozen_string_literal: true

FactoryBot.define do
  factory :consultee_response, class: "Consultee::Response" do
    name { Faker::Name.name }
    summary_tag { "approved" }
    response { Faker::Lorem.paragraph }
    received_at { Time.current }
    redacted_response { "I like it *** " }
  end

  trait :with_redaction do
    redacted_response { "I like it *** " }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_requirement, class: "LocalAuthority::Requirement" do
    local_authority
    description { Faker::Lorem.unique.sentence }
  end
end

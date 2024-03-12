# frozen_string_literal: true

FactoryBot.define do
  factory :time_extension_validation_request do
    planning_application { create(:planning_application, :not_started) }
    user
    state { "open" }
    proposed_expiry_date { 200.days.from_now }
    approved { nil }
    post_validation { true }
    condition

    trait :pending do
      state { "pending" }
    end

    trait :open do
      state { "open" }
    end

    trait :closed do
      state { "closed" }
    end

    trait :cancelled do
      state { "cancelled" }
      cancel_reason { "Made by mistake!" }
      cancelled_at { Time.current }
    end
  end
end

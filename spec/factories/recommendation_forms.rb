# frozen_string_literal: true

FactoryBot.define do
  factory :recommendation_form do
    recommendation { association :recommendation, :with_planning_application }
    decision { :granted }
    recommend { false }
    public_comment { "GDPO compliant" }
  end
end

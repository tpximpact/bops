# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to show document file" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let!(:planning_application) { create(:planning_application, :not_started, local_authority: default_local_authority) }
  let!(:document) { create(:document, :with_file, :public, planning_application:) }

  describe "data" do
    it "returns a 404 if no planning application" do
      expect do
        get "/api/v1/planning_applications/xxx/documents/#{document.id}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns a 404 if no document" do
      expect do
        get "/api/v1/planning_applications/#{planning_application.reference}/documents/xxx"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with a document that is not public" do
      let!(:document) { create(:document, :with_file, planning_application:) }

      it "returns a 404" do
        expect do
          get "/api/v1/planning_applications/#{planning_application.reference}/documents/#{document.id}"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a document that has been archived" do
      let!(:document) do
        create(:document, :with_file, :referenced, :archived, planning_application:)
      end

      it "returns a 404" do
        expect do
          get "/api/v1/planning_applications/#{planning_application.reference}/documents/#{document.id}"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "redirects to blob url" do
      get "/api/v1/planning_applications/#{planning_application.reference}/documents/#{document.id}"
      expect(response).to redirect_to(rails_blob_path(document.file))
    end
  end
end

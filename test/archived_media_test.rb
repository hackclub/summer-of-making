# frozen_string_literal: true

require "test_helper"

class ArchivedMediaTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "uploads are rejected without reading a file" do
    controller = AttachmentsController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.set_response!(ActionDispatch::TestResponse.new)

    controller.upload

    assert_equal 410, controller.response.status
    assert_match "Uploads are closed", JSON.parse(controller.response.body).fetch("error")
  end

  test "stored originals do not require an image processor" do
    blob = ActiveStorage::Blob.new(filename: "archive.png", content_type: "image/png")

    refute blob.variable?
    refute blob.previewable?
    analyzed_metadata = nil
    blob.define_singleton_method(:update!) { |**attributes| analyzed_metadata = attributes.fetch(:metadata) }
    blob.analyze
    assert analyzed_metadata.fetch(:analyzed)

    blob.define_singleton_method(:signed_id) { |**| "archived-original" }
    path = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    assert_includes path, "/blobs/"
    assert_includes path, "/archive.png"
    refute_includes path, "/representations/"
  end

  test "queued media jobs complete without looking up or downloading media" do
    assert_nothing_raised do
      VideoConversionJob.new.perform(-1)
      GenerateStonkNewsVideoJob.new.perform
    end
  end
end

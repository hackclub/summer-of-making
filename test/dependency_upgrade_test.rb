# frozen_string_literal: true

require "test_helper"

class DependencyUpgradeTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "API pagination retains its response keys and returns the requested page" do
    controller = api_controller(page: 2)
    controller.send(:render_paginated, (1..45).to_a)

    body = JSON.parse(controller.response.body)
    assert_equal (21..40).to_a, body.fetch("data")
    assert_equal({ "page" => 2, "pages" => 3, "count" => 45, "items" => 20 }, body.fetch("pagination"))
  end

  test "API pagination still returns 404 for pages past the end" do
    controller = api_controller(page: 4)
    controller.send(:render_paginated, (1..45).to_a)

    assert_equal 404, controller.response.status
    assert_equal "not found", JSON.parse(controller.response.body).fetch("error")
  end

  test "pagination navigation and info render links and totals" do
    controller = api_controller(page: 2)
    pagy, = controller.send(:pagy, (1..45).to_a, limit: 8)

    assert_equal 8, pagy.limit
    assert_includes pagy.series_nav, 'href="/api/v2/projects?page=3"'
    assert_includes pagy.info_tag, "45"
  end

  test "failed order persistence still returns false instead of raising" do
    order = ShopOrder.new
    order.define_singleton_method(:valid?) { |*| false }

    assert_equal false, order.mark_fulfilled!
    refute order.persisted?
  end

  test "Identity Vault parameters preserve Unicode through UTF16 compression" do
    params = { "name" => "Hacker 🚀 ö", "return_to" => "/identity" }
    encoded = IdentityVaultService.send(:encode_sneaky_params, params)
    compressed = Base64.urlsafe_decode64(encoded).force_encoding(Encoding::UTF_8)

    assert_equal params, JSON.parse(LZString::UTF16.decompress(compressed))
  end

  private

  def api_controller(page:)
    Api::V2::BaseController.new.tap do |controller|
      controller.request = ActionDispatch::TestRequest.create
      controller.request.path_info = "/api/v2/projects"
      controller.request.set_header("QUERY_STRING", "page=#{page}")
      controller.set_response!(ActionDispatch::TestResponse.new)
    end
  end
end
